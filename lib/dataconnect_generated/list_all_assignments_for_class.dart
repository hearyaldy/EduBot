part of 'generated.dart';

class ListAllAssignmentsForClassVariablesBuilder {
  String classId;

  final FirebaseDataConnect _dataConnect;
  ListAllAssignmentsForClassVariablesBuilder(this._dataConnect, {required  this.classId,});
  Deserializer<ListAllAssignmentsForClassData> dataDeserializer = (dynamic json)  => ListAllAssignmentsForClassData.fromJson(jsonDecode(json));
  Serializer<ListAllAssignmentsForClassVariables> varsSerializer = (ListAllAssignmentsForClassVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<ListAllAssignmentsForClassData, ListAllAssignmentsForClassVariables>> execute() {
    return ref().execute();
  }

  QueryRef<ListAllAssignmentsForClassData, ListAllAssignmentsForClassVariables> ref() {
    ListAllAssignmentsForClassVariables vars= ListAllAssignmentsForClassVariables(classId: classId,);
    return _dataConnect.query("ListAllAssignmentsForClass", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class ListAllAssignmentsForClassAssignments {
  final String title;
  final String? description;
  final Timestamp dueDate;
  final String status;
  final List<ListAllAssignmentsForClassAssignmentsResourcesOnAssignment> resources_on_assignment;
  ListAllAssignmentsForClassAssignments.fromJson(dynamic json):
  
  title = nativeFromJson<String>(json['title']),
  description = json['description'] == null ? null : nativeFromJson<String>(json['description']),
  dueDate = Timestamp.fromJson(json['dueDate']),
  status = nativeFromJson<String>(json['status']),
  resources_on_assignment = (json['resources_on_assignment'] as List<dynamic>)
        .map((e) => ListAllAssignmentsForClassAssignmentsResourcesOnAssignment.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListAllAssignmentsForClassAssignments otherTyped = other as ListAllAssignmentsForClassAssignments;
    return title == otherTyped.title && 
    description == otherTyped.description && 
    dueDate == otherTyped.dueDate && 
    status == otherTyped.status && 
    resources_on_assignment == otherTyped.resources_on_assignment;
    
  }
  @override
  int get hashCode => Object.hashAll([title.hashCode, description.hashCode, dueDate.hashCode, status.hashCode, resources_on_assignment.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['title'] = nativeToJson<String>(title);
    if (description != null) {
      json['description'] = nativeToJson<String?>(description);
    }
    json['dueDate'] = dueDate.toJson();
    json['status'] = nativeToJson<String>(status);
    json['resources_on_assignment'] = resources_on_assignment.map((e) => e.toJson()).toList();
    return json;
  }

  ListAllAssignmentsForClassAssignments({
    required this.title,
    this.description,
    required this.dueDate,
    required this.status,
    required this.resources_on_assignment,
  });
}

@immutable
class ListAllAssignmentsForClassAssignmentsResourcesOnAssignment {
  final String type;
  final String content;
  final String? description;
  ListAllAssignmentsForClassAssignmentsResourcesOnAssignment.fromJson(dynamic json):
  
  type = nativeFromJson<String>(json['type']),
  content = nativeFromJson<String>(json['content']),
  description = json['description'] == null ? null : nativeFromJson<String>(json['description']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListAllAssignmentsForClassAssignmentsResourcesOnAssignment otherTyped = other as ListAllAssignmentsForClassAssignmentsResourcesOnAssignment;
    return type == otherTyped.type && 
    content == otherTyped.content && 
    description == otherTyped.description;
    
  }
  @override
  int get hashCode => Object.hashAll([type.hashCode, content.hashCode, description.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['type'] = nativeToJson<String>(type);
    json['content'] = nativeToJson<String>(content);
    if (description != null) {
      json['description'] = nativeToJson<String?>(description);
    }
    return json;
  }

  ListAllAssignmentsForClassAssignmentsResourcesOnAssignment({
    required this.type,
    required this.content,
    this.description,
  });
}

@immutable
class ListAllAssignmentsForClassData {
  final List<ListAllAssignmentsForClassAssignments> assignments;
  ListAllAssignmentsForClassData.fromJson(dynamic json):
  
  assignments = (json['assignments'] as List<dynamic>)
        .map((e) => ListAllAssignmentsForClassAssignments.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListAllAssignmentsForClassData otherTyped = other as ListAllAssignmentsForClassData;
    return assignments == otherTyped.assignments;
    
  }
  @override
  int get hashCode => assignments.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['assignments'] = assignments.map((e) => e.toJson()).toList();
    return json;
  }

  ListAllAssignmentsForClassData({
    required this.assignments,
  });
}

@immutable
class ListAllAssignmentsForClassVariables {
  final String classId;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  ListAllAssignmentsForClassVariables.fromJson(Map<String, dynamic> json):
  
  classId = nativeFromJson<String>(json['classId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListAllAssignmentsForClassVariables otherTyped = other as ListAllAssignmentsForClassVariables;
    return classId == otherTyped.classId;
    
  }
  @override
  int get hashCode => classId.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['classId'] = nativeToJson<String>(classId);
    return json;
  }

  ListAllAssignmentsForClassVariables({
    required this.classId,
  });
}

