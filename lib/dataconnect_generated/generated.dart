library dataconnect_generated;
import 'package:firebase_data_connect/firebase_data_connect.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

part 'create_new_parent.dart';

part 'get_my_children.dart';

part 'create_new_class.dart';

part 'list_all_assignments_for_class.dart';







class ExampleConnector {
  
  
  CreateNewParentVariablesBuilder createNewParent ({required String displayName, }) {
    return CreateNewParentVariablesBuilder(dataConnect, displayName: displayName,);
  }
  
  
  GetMyChildrenVariablesBuilder getMyChildren () {
    return GetMyChildrenVariablesBuilder(dataConnect, );
  }
  
  
  CreateNewClassVariablesBuilder createNewClass ({required String childId, required String name, required String subject, }) {
    return CreateNewClassVariablesBuilder(dataConnect, childId: childId,name: name,subject: subject,);
  }
  
  
  ListAllAssignmentsForClassVariablesBuilder listAllAssignmentsForClass ({required String classId, }) {
    return ListAllAssignmentsForClassVariablesBuilder(dataConnect, classId: classId,);
  }
  

  static ConnectorConfig connectorConfig = ConnectorConfig(
    'us-east4',
    'example',
    'edubot',
  );

  ExampleConnector({required this.dataConnect});
  static ExampleConnector get instance {
    return ExampleConnector(
        dataConnect: FirebaseDataConnect.instanceFor(
            connectorConfig: connectorConfig,
            sdkType: CallerSDKType.generated));
  }

  FirebaseDataConnect dataConnect;
}
