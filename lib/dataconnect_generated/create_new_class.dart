part of 'generated.dart';

class CreateNewClassVariablesBuilder {
  String childId;
  String name;
  String subject;
  Optional<String> _teacherName = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _teacherContactInfo = Optional.optional(nativeFromJson, nativeToJson);

  final FirebaseDataConnect _dataConnect;  CreateNewClassVariablesBuilder teacherName(String? t) {
   _teacherName.value = t;
   return this;
  }
  CreateNewClassVariablesBuilder teacherContactInfo(String? t) {
   _teacherContactInfo.value = t;
   return this;
  }

  CreateNewClassVariablesBuilder(this._dataConnect, {required  this.childId,required  this.name,required  this.subject,});
  Deserializer<CreateNewClassData> dataDeserializer = (dynamic json)  => CreateNewClassData.fromJson(jsonDecode(json));
  Serializer<CreateNewClassVariables> varsSerializer = (CreateNewClassVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<CreateNewClassData, CreateNewClassVariables>> execute() {
    return ref().execute();
  }

  MutationRef<CreateNewClassData, CreateNewClassVariables> ref() {
    CreateNewClassVariables vars= CreateNewClassVariables(childId: childId,name: name,subject: subject,teacherName: _teacherName,teacherContactInfo: _teacherContactInfo,);
    return _dataConnect.mutation("CreateNewClass", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class CreateNewClassClassInsert {
  final String id;
  CreateNewClassClassInsert.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateNewClassClassInsert otherTyped = other as CreateNewClassClassInsert;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  CreateNewClassClassInsert({
    required this.id,
  });
}

@immutable
class CreateNewClassData {
  final CreateNewClassClassInsert class_insert;
  CreateNewClassData.fromJson(dynamic json):
  
  class_insert = CreateNewClassClassInsert.fromJson(json['class_insert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateNewClassData otherTyped = other as CreateNewClassData;
    return class_insert == otherTyped.class_insert;
    
  }
  @override
  int get hashCode => class_insert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['class_insert'] = class_insert.toJson();
    return json;
  }

  CreateNewClassData({
    required this.class_insert,
  });
}

@immutable
class CreateNewClassVariables {
  final String childId;
  final String name;
  final String subject;
  late final Optional<String>teacherName;
  late final Optional<String>teacherContactInfo;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  CreateNewClassVariables.fromJson(Map<String, dynamic> json):
  
  childId = nativeFromJson<String>(json['childId']),
  name = nativeFromJson<String>(json['name']),
  subject = nativeFromJson<String>(json['subject']) {
  
  
  
  
  
    teacherName = Optional.optional(nativeFromJson, nativeToJson);
    teacherName.value = json['teacherName'] == null ? null : nativeFromJson<String>(json['teacherName']);
  
  
    teacherContactInfo = Optional.optional(nativeFromJson, nativeToJson);
    teacherContactInfo.value = json['teacherContactInfo'] == null ? null : nativeFromJson<String>(json['teacherContactInfo']);
  
  }
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateNewClassVariables otherTyped = other as CreateNewClassVariables;
    return childId == otherTyped.childId && 
    name == otherTyped.name && 
    subject == otherTyped.subject && 
    teacherName == otherTyped.teacherName && 
    teacherContactInfo == otherTyped.teacherContactInfo;
    
  }
  @override
  int get hashCode => Object.hashAll([childId.hashCode, name.hashCode, subject.hashCode, teacherName.hashCode, teacherContactInfo.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['childId'] = nativeToJson<String>(childId);
    json['name'] = nativeToJson<String>(name);
    json['subject'] = nativeToJson<String>(subject);
    if(teacherName.state == OptionalState.set) {
      json['teacherName'] = teacherName.toJson();
    }
    if(teacherContactInfo.state == OptionalState.set) {
      json['teacherContactInfo'] = teacherContactInfo.toJson();
    }
    return json;
  }

  CreateNewClassVariables({
    required this.childId,
    required this.name,
    required this.subject,
    required this.teacherName,
    required this.teacherContactInfo,
  });
}

