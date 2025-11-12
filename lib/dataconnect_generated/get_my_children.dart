part of 'generated.dart';

class GetMyChildrenVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  GetMyChildrenVariablesBuilder(this._dataConnect, );
  Deserializer<GetMyChildrenData> dataDeserializer = (dynamic json)  => GetMyChildrenData.fromJson(jsonDecode(json));
  
  Future<QueryResult<GetMyChildrenData, void>> execute() {
    return ref().execute();
  }

  QueryRef<GetMyChildrenData, void> ref() {
    
    return _dataConnect.query("GetMyChildren", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class GetMyChildrenParents {
  final List<GetMyChildrenParentsChildrenOnParent> children_on_parent;
  GetMyChildrenParents.fromJson(dynamic json):
  
  children_on_parent = (json['children_on_parent'] as List<dynamic>)
        .map((e) => GetMyChildrenParentsChildrenOnParent.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetMyChildrenParents otherTyped = other as GetMyChildrenParents;
    return children_on_parent == otherTyped.children_on_parent;
    
  }
  @override
  int get hashCode => children_on_parent.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['children_on_parent'] = children_on_parent.map((e) => e.toJson()).toList();
    return json;
  }

  GetMyChildrenParents({
    required this.children_on_parent,
  });
}

@immutable
class GetMyChildrenParentsChildrenOnParent {
  final String name;
  final String gradeLevel;
  final String? school;
  GetMyChildrenParentsChildrenOnParent.fromJson(dynamic json):
  
  name = nativeFromJson<String>(json['name']),
  gradeLevel = nativeFromJson<String>(json['gradeLevel']),
  school = json['school'] == null ? null : nativeFromJson<String>(json['school']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetMyChildrenParentsChildrenOnParent otherTyped = other as GetMyChildrenParentsChildrenOnParent;
    return name == otherTyped.name && 
    gradeLevel == otherTyped.gradeLevel && 
    school == otherTyped.school;
    
  }
  @override
  int get hashCode => Object.hashAll([name.hashCode, gradeLevel.hashCode, school.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['name'] = nativeToJson<String>(name);
    json['gradeLevel'] = nativeToJson<String>(gradeLevel);
    if (school != null) {
      json['school'] = nativeToJson<String?>(school);
    }
    return json;
  }

  GetMyChildrenParentsChildrenOnParent({
    required this.name,
    required this.gradeLevel,
    this.school,
  });
}

@immutable
class GetMyChildrenData {
  final List<GetMyChildrenParents> parents;
  GetMyChildrenData.fromJson(dynamic json):
  
  parents = (json['parents'] as List<dynamic>)
        .map((e) => GetMyChildrenParents.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetMyChildrenData otherTyped = other as GetMyChildrenData;
    return parents == otherTyped.parents;
    
  }
  @override
  int get hashCode => parents.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['parents'] = parents.map((e) => e.toJson()).toList();
    return json;
  }

  GetMyChildrenData({
    required this.parents,
  });
}

