import sys
import os
import debugpy
import json
import pyodbc
import socket
from flask import Flask,jsonify, request
from flask_restful import reqparse, abort, Api, Resource
from threading import Lock
from tenacity import *
from opencensus.ext.azure.trace_exporter import AzureExporter
from opencensus.ext.flask.flask_middleware import FlaskMiddleware
from opencensus.trace.samplers import ProbabilitySampler
import logging

app = Flask(__name__)


# Setup Azure Monitor
if 'APPINSIGHTS_KEY' in os.environ:
    middleware = FlaskMiddleware(
        app,
        exporter=AzureExporter(connection_string="InstrumentationKey={0}".format(os.environ['APPINSIGHTS_KEY'])),
        sampler=ProbabilitySampler(rate=1.0),
    )

# Setup Flask Restful framework
api = Api(app)
parser = reqparse.RequestParser()
parser.add_argument('SentenceText')
parser.add_argument('email')
parser.add_argument('PersonId')
parser.add_argument('SentenceId')
parser.add_argument('StoragePath')

# Implement singleton to avoid global objects
class ConnectionManager(object):    
    __instance = None
    __connection = None
    __lock = Lock()

    def __new__(cls):
        if ConnectionManager.__instance is None:
            ConnectionManager.__instance = object.__new__(cls)        
        return ConnectionManager.__instance       
    
    def __getConnection(self):
        if (self.__connection == None):
            application_name = ";APP={0}".format(socket.gethostname())  
            self.__connection = pyodbc.connect(os.environ['SQLAZURECONNSTR_WWIF'] + application_name)                  
        
        return self.__connection

    def __removeConnection(self):
        self.__connection = None

    @retry(stop=stop_after_attempt(3), wait=wait_fixed(10), retry=retry_if_exception_type(pyodbc.OperationalError), after=after_log(app.logger, logging.DEBUG))
    def executeQueryJSON(self, procedure, payload=None):
        result = {}  
        try:
            conn = self.__getConnection()

            cursor = conn.cursor()
            
            if payload:
                cursor.execute(f"EXEC {procedure} ?", json.dumps(payload))
            else:
                cursor.execute(f"EXEC {procedure}")
        
            result = cursor.fetchone()

            if result:
                result = json.loads(result[0])                           
            else:
                result = {}

            cursor.commit()
            cursor.close()    
        except pyodbc.OperationalError as e:            
            app.logger.error(f"{e.args[1]}")
            if e.args[0] == "08S01":
                # If there is a "Communication Link Failure" error, 
                # then connection must be removed
                # as it will be in an invalid state
                self.__removeConnection() 
                raise 
        except:
            self.__removeConnection()
            cursor.close()
            raise
                               
                         
        return result

class Queryable(Resource):
    def executeQueryJson(self, verb, payload=None):
        result = {}  
        entity = type(self).__name__.lower()
        procedure = f"web.{verb}_{entity}"
        result = ConnectionManager().executeQueryJSON(procedure, payload)
        return result

# sentence Class
class Sentence(Queryable):
    def get(self, sentence_id):     
        sentence = {}
        sentence["SentenceId"] = sentence_id
        result = self.executeQueryJson("get", sentence) 
        result['videosURL']=f'/videos/sentences/{sentence_id}'
        result['personsURL']=f'/persons/sentence/{sentence_id}'
        return result, 200
    
    def put(self):
        sentence={}
        args = parser.parse_args()
        sentence['SentenceText'] = args['SentenceText']
        result = self.executeQueryJson("put", sentence)
        return result, 201

    def patch(self, sentence_id):
        args = parser.parse_args()
        sentence={}
        sentence['SentenceId']=json.loads(sentence_id)
        sentence["SentenceText"] = args['SentenceText']           
        result = self.executeQueryJson("patch", sentence)
        return result, 202

    def delete(self, sentence_id):      
        sentence = {}
        sentence["SentenceId"] = sentence_id
        result = self.executeQueryJson("delete", sentence)
        return result, 203

# sentences Class
class Sentences(Queryable):
    def get(self):     
        result = self.executeQueryJson("get")   
        return result, 200

class SentencesByPerson(Queryable):
    def get(self,person_id):
        person = {}
        person["PersonId"] = person_id
        result= self.executeQueryJson("get",person)
        return result, 200

class SentencesByCount(Queryable):
    def get(self):
        result=self.executeQueryJson("get")
        return result, 200
# Create API routes
api.add_resource(Sentence, '/sentence', '/sentence/<sentence_id>')
api.add_resource(Sentences, '/sentences')
api.add_resource(SentencesByPerson,'/sentences/<person_id>')
api.add_resource(SentencesByCount,'/count')

class Person(Queryable):
    def get(self, person_id):     
        person= {}
        person['PersonId'] = json.loads(person_id)
        result = self.executeQueryJson("get", person)
        result['sentencesURL']=f'/sentences/{person_id}'
        result['videosURL']=f'/videos/persons/{person_id}'   
        return result, 200
    
    def put(self):
        person={}
        args = parser.parse_args()
        person['email'] = args['email']
        result = self.executeQueryJson("put", person)
        return result, 201

    def patch(self, person_id):
        args = parser.parse_args()
        person={}
        person['PersonId']=json.loads(person_id)
        person["email"] = args['email']           
        result = self.executeQueryJson("patch", person)
        return result, 202

    def delete(self, person_id):    
        person = {}
        person["PersonId"] = person_id
        result = self.executeQueryJson("delete", person)
        return result, 203

# persons Class
class Persons(Queryable):
    def get(self):
        result = self.executeQueryJson("get")   
        return result, 200

class PersonByEmail(Queryable):
    def get(self):
        email={}
        email['email'] = request.args.get('email')
        result=self.executeQueryJson("get",email)
        return result,200

class PersonsBySentence(Queryable):
    def get(self,sentence_id):
        sentence={}
        sentence['SentenceId']=json.loads(sentence_id)
        result=self.executeQueryJson("get",sentence)
        return result, 200

api.add_resource(Person, '/person', '/person/<person_id>')
api.add_resource(Persons, '/persons')
api.add_resource(PersonByEmail,'/email')
api.add_resource(PersonsBySentence,'/persons/sentence/<sentence_id>')


    
# Create Video API 


class Video(Queryable):
    def get(self, video_id):     
        video= {}
        video['VideoId'] = json.loads(video_id)
        result = self.executeQueryJson("get", video)   
        return result, 200
    
    def put(self):
        video={}
        args = parser.parse_args()
        video['PersonId'] = args['PersonId']
        video['SentenceId']=args['SentenceId']
        video['StoragePath']=args['StoragePath']
        result = self.executeQueryJson("put", video)
        return result, 201

    def patch(self, video_id):
        args = parser.parse_args()
        video={}
        video['VideoId']=json.loads(video_id)
        for arg in args: 
            val=args[arg]
            if val!=None:
                if arg=='StoragePath':
                    video[arg]=val
                else:
                    video[arg] = json.loads(val)         
        result = self.executeQueryJson("patch", video)
        return result, 202

    def delete(self, video_id):  
        video = {}
        video["VideoId"] = video_id
        result = self.executeQueryJson("delete", video)
        return result, 203

# videos Class
class Videos(Queryable):
    def get(self):     
        result = self.executeQueryJson("get")   
        return result, 200

class VideosBySentence(Queryable):
    def get(self,sentence_id):
        sentence={}
        sentence['SentenceId']=sentence_id
        result=self.executeQueryJson("get",sentence)
        return result,200

class VideosByPerson(Queryable):
    def get(self,person_id):
        person={}
        person['PersonId']=person_id
        result=self.executeQueryJson("get",person)
        return result, 200
    


api.add_resource(Video, '/video', '/video/<video_id>')
api.add_resource(Videos, '/videos')
api.add_resource(VideosBySentence,'/videos/sentences/<sentence_id>')
api.add_resource(VideosByPerson,'/videos/persons/<person_id>')
#test

if __name__ == '__main__':
    app.run()