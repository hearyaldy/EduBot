part of 'generated.dart';

class CreateNewParentVariablesBuilder {
  String displayName;
  Optional<String> _email = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _photoUrl = Optional.optional(nativeFromJson, nativeToJson);

  final FirebaseDataConnect _dataConnect;  CreateNewParentVariablesBuilder email(String? t) {
   _email.value = t;
   return this;
  }
  CreateNewParentVariablesBuilder photoUrl(String? t) {
   _photoUrl.value = t;
   return this;
  }

  CreateNewParentVariablesBuilder(this._dataConnect, {required  this.displayName,});
  Deserializer<CreateNewParentData> dataDeserializer = (dynamic json)  => CreateNewParentData.fromJson(jsonDecode(json));
  Serializer<CreateNewParentVariables> varsSerializer = (CreateNewParentVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<CreateNewParentData, CreateNewParentVariables>> execute() {
    return ref().execute();
  }

  MutationRef<CreateNewParentData, CreateNewParentVariables> ref() {
    CreateNewParentVariables vars= CreateNewParentVariables(displayName: displayName,email: _email,photoUrl: _photoUrl,);
    return _dataConnect.mutation("CreateNewParent", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class CreateNewParentParentInsert {
  final String id;
  CreateNewParentParentInsert.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateNewParentParentInsert otherTyped = other as CreateNewParentParentInsert;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  CreateNewParentParentInsert({
    required this.id,
  });
}

@immutable
class CreateNewParentData {
  final CreateNewParentParentInsert parent_insert;
  CreateNewParentData.fromJson(dynamic json):
  
  parent_insert = CreateNewParentParentInsert.fromJson(json['parent_insert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateNewParentData otherTyped = other as CreateNewParentData;
    return parent_insert == otherTyped.parent_insert;
    
  }
  @override
  int get hashCode => parent_insert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['parent_insert'] = parent_insert.toJson();
    return json;
  }

  CreateNewParentData({
    required this.parent_insert,
  });
}

@immutable
class CreateNewParentVariables {
  final String displayName;
  late final Optional<String>email;
  late final Optional<String>photoUrl;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  CreateNewParentVariables.fromJson(Map<String, dynamic> json):
  
  displayName = nativeFromJson<String>(json['displayName']) {
  
  
  
    email = Optional.optional(nativeFromJson, nativeToJson);
    email.value = json['email'] == null ? null : nativeFromJson<String>(json['email']);
  
  
    photoUrl = Optional.optional(nativeFromJson, nativeToJson);
    photoUrl.value = json['photoUrl'] == null ? null : nativeFromJson<String>(json['photoUrl']);
  
  }
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateNewParentVariables otherTyped = other as CreateNewParentVariables;
    return displayName == otherTyped.displayName && 
    email == otherTyped.email && 
    photoUrl == otherTyped.photoUrl;
    
  }
  @override
  int get hashCode => Object.hashAll([displayName.hashCode, email.hashCode, photoUrl.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['displayName'] = nativeToJson<String>(displayName);
    if(email.state == OptionalState.set) {
      json['email'] = email.toJson();
    }
    if(photoUrl.state == OptionalState.set) {
      json['photoUrl'] = photoUrl.toJson();
    }
    return json;
  }

  CreateNewParentVariables({
    required this.displayName,
    required this.email,
    required this.photoUrl,
  });
}

