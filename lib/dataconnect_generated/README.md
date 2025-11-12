# dataconnect_generated SDK

## Installation
```sh
flutter pub get firebase_data_connect
flutterfire configure
```
For more information, see [Flutter for Firebase installation documentation](https://firebase.google.com/docs/data-connect/flutter-sdk#use-core).

## Data Connect instance
Each connector creates a static class, with an instance of the `DataConnect` class that can be used to connect to your Data Connect backend and call operations.

### Connecting to the emulator

```dart
String host = 'localhost'; // or your host name
int port = 9399; // or your port number
ExampleConnector.instance.dataConnect.useDataConnectEmulator(host, port);
```

You can also call queries and mutations by using the connector class.
## Queries

### GetMyChildren
#### Required Arguments
```dart
// No required arguments
ExampleConnector.instance.getMyChildren().execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetMyChildrenData, void>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await ExampleConnector.instance.getMyChildren();
GetMyChildrenData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
final ref = ExampleConnector.instance.getMyChildren().ref();
ref.execute();

ref.subscribe(...);
```


### ListAllAssignmentsForClass
#### Required Arguments
```dart
String classId = ...;
ExampleConnector.instance.listAllAssignmentsForClass(
  classId: classId,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<ListAllAssignmentsForClassData, ListAllAssignmentsForClassVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await ExampleConnector.instance.listAllAssignmentsForClass(
  classId: classId,
);
ListAllAssignmentsForClassData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String classId = ...;

final ref = ExampleConnector.instance.listAllAssignmentsForClass(
  classId: classId,
).ref();
ref.execute();

ref.subscribe(...);
```

## Mutations

### CreateNewParent
#### Required Arguments
```dart
String displayName = ...;
ExampleConnector.instance.createNewParent(
  displayName: displayName,
).execute();
```

#### Optional Arguments
We return a builder for each query. For CreateNewParent, we created `CreateNewParentBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class CreateNewParentVariablesBuilder {
  ...
   CreateNewParentVariablesBuilder email(String? t) {
   _email.value = t;
   return this;
  }
  CreateNewParentVariablesBuilder photoUrl(String? t) {
   _photoUrl.value = t;
   return this;
  }

  ...
}
ExampleConnector.instance.createNewParent(
  displayName: displayName,
)
.email(email)
.photoUrl(photoUrl)
.execute();
```

#### Return Type
`execute()` returns a `OperationResult<CreateNewParentData, CreateNewParentVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.createNewParent(
  displayName: displayName,
);
CreateNewParentData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String displayName = ...;

final ref = ExampleConnector.instance.createNewParent(
  displayName: displayName,
).ref();
ref.execute();
```


### CreateNewClass
#### Required Arguments
```dart
String childId = ...;
String name = ...;
String subject = ...;
ExampleConnector.instance.createNewClass(
  childId: childId,
  name: name,
  subject: subject,
).execute();
```

#### Optional Arguments
We return a builder for each query. For CreateNewClass, we created `CreateNewClassBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class CreateNewClassVariablesBuilder {
  ...
   CreateNewClassVariablesBuilder teacherName(String? t) {
   _teacherName.value = t;
   return this;
  }
  CreateNewClassVariablesBuilder teacherContactInfo(String? t) {
   _teacherContactInfo.value = t;
   return this;
  }

  ...
}
ExampleConnector.instance.createNewClass(
  childId: childId,
  name: name,
  subject: subject,
)
.teacherName(teacherName)
.teacherContactInfo(teacherContactInfo)
.execute();
```

#### Return Type
`execute()` returns a `OperationResult<CreateNewClassData, CreateNewClassVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.createNewClass(
  childId: childId,
  name: name,
  subject: subject,
);
CreateNewClassData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String childId = ...;
String name = ...;
String subject = ...;

final ref = ExampleConnector.instance.createNewClass(
  childId: childId,
  name: name,
  subject: subject,
).ref();
ref.execute();
```

