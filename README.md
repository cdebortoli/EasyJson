#EasyJson
----------

EasyJson is a library to manage the parsing between NSManagedObject/NSObject and JSON elements.

##How to install it

 1. Copy the content of EasyJson folder in your project.
 2. Create a EasyJsonConfig.json file based on the EasyJsonConfig.json.tpl template file.
 3. Configure your EasyJsonConfig.json file. 

##Configure it
###EasyJsonConfig file
The rool level of this file is an array which contain each object available for the JSON Parsing.

Two kinds of object can be specified in this file:

**NSManagedObject**

     {
        "class" : { "attribute"  : "ManagedObjectClassName", "json" : "JSONKey" },
        "parameters" : [
                     { "attribute": "ManagedObjectAttributeName", "json": "JSONKey" },
                     { "attribute": "ManagedObjectAttributeName", "json": "JSONKey" }
                    ]
    }

**NSObject**

     {
        "class" : { "attribute" : "NSObjectClassName", "json": "JSONKey" },
        "parameters" : [
                    { "attribute": "NSObjectAttributeName", "json": "JSONKey" },
                    { "attribute": "NSObjectAttributeName", "json": "JSONKey" },
                    { "attribute": "NSObjectAttributeArrayName", "json": "JSONKey", "type": "ObjectTypeInArray" },
                    { "attribute": "NSObjectAttributeDictionaryName", "json": "JSONKey", "type": "ObjectTypeInDictionary" }
                   ]
    }
For NSArray and NSDictionary attributes, you need to specify the type of objects contained in these attributes.

###Configuration variables

Two configuration variables are defined in the EJSEasyJson header.

**EASY_JSON_ENVELOPE_WITH_OBJECT_NAME**
Set to 1 if your JSON data is specified by a key value.
Example for an Aircraft object:

    { "Aircraft": { "AircraftId": 1, "AircraftName": "Airbus" } }

By setting the variable to 0, you JSON data could be used without key.
Example for an Aircraft object:

    { "AircraftId": 1, "AircraftName": "Airbus" }

**EASY_JSON_DATE_FORMAT**
Specify the date format used in the JSON data.

##How to use it

 - Analyze a NSManagedObject:

    NSManagedObject *managedObject = [[EJSEasyJson sharedInstance] analyzeDictionary:JSONDictionary forClass:[NSManagedObject class]];

 - Analyze an Array of NSManagedObject:

    NSArray *managedObjects = [[EJSEasyJson sharedInstance] analyzeDictionary:JSONArray forClass:[NSManagedObject class]];

 


##Integrate tests

 1. Copy the EasyJsonTests.m file in your Test Target.
 2. Create the mocks of your JSON Services with files which follows this name pattern : "EasyJsonMock[CustomTitle].json". Replace [CustomTitle] by the title of your choice.
 3. Run the tests.