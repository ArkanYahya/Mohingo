// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $LearnersTable extends Learners with TableInfo<$LearnersTable, Learner> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LearnersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nativeLanguageMeta = const VerificationMeta(
    'nativeLanguage',
  );
  @override
  late final GeneratedColumn<String> nativeLanguage = GeneratedColumn<String>(
    'native_language',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('ar'),
  );
  static const VerificationMeta _targetLanguageMeta = const VerificationMeta(
    'targetLanguage',
  );
  @override
  late final GeneratedColumn<String> targetLanguage = GeneratedColumn<String>(
    'target_language',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('en'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    uuid,
    name,
    nativeLanguage,
    targetLanguage,
    createdAt,
    isActive,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'learners';
  @override
  VerificationContext validateIntegrity(
    Insertable<Learner> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('native_language')) {
      context.handle(
        _nativeLanguageMeta,
        nativeLanguage.isAcceptableOrUnknown(
          data['native_language']!,
          _nativeLanguageMeta,
        ),
      );
    }
    if (data.containsKey('target_language')) {
      context.handle(
        _targetLanguageMeta,
        targetLanguage.isAcceptableOrUnknown(
          data['target_language']!,
          _targetLanguageMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Learner map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Learner(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
      nativeLanguage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}native_language'],
      )!,
      targetLanguage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_language'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
    );
  }

  @override
  $LearnersTable createAlias(String alias) {
    return $LearnersTable(attachedDatabase, alias);
  }
}

class Learner extends DataClass implements Insertable<Learner> {
  final int id;
  final String uuid;
  final String? name;
  final String nativeLanguage;
  final String targetLanguage;
  final DateTime createdAt;
  final bool isActive;
  const Learner({
    required this.id,
    required this.uuid,
    this.name,
    required this.nativeLanguage,
    required this.targetLanguage,
    required this.createdAt,
    required this.isActive,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    map['native_language'] = Variable<String>(nativeLanguage);
    map['target_language'] = Variable<String>(targetLanguage);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['is_active'] = Variable<bool>(isActive);
    return map;
  }

  LearnersCompanion toCompanion(bool nullToAbsent) {
    return LearnersCompanion(
      id: Value(id),
      uuid: Value(uuid),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      nativeLanguage: Value(nativeLanguage),
      targetLanguage: Value(targetLanguage),
      createdAt: Value(createdAt),
      isActive: Value(isActive),
    );
  }

  factory Learner.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Learner(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      name: serializer.fromJson<String?>(json['name']),
      nativeLanguage: serializer.fromJson<String>(json['nativeLanguage']),
      targetLanguage: serializer.fromJson<String>(json['targetLanguage']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      isActive: serializer.fromJson<bool>(json['isActive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'name': serializer.toJson<String?>(name),
      'nativeLanguage': serializer.toJson<String>(nativeLanguage),
      'targetLanguage': serializer.toJson<String>(targetLanguage),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'isActive': serializer.toJson<bool>(isActive),
    };
  }

  Learner copyWith({
    int? id,
    String? uuid,
    Value<String?> name = const Value.absent(),
    String? nativeLanguage,
    String? targetLanguage,
    DateTime? createdAt,
    bool? isActive,
  }) => Learner(
    id: id ?? this.id,
    uuid: uuid ?? this.uuid,
    name: name.present ? name.value : this.name,
    nativeLanguage: nativeLanguage ?? this.nativeLanguage,
    targetLanguage: targetLanguage ?? this.targetLanguage,
    createdAt: createdAt ?? this.createdAt,
    isActive: isActive ?? this.isActive,
  );
  Learner copyWithCompanion(LearnersCompanion data) {
    return Learner(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      name: data.name.present ? data.name.value : this.name,
      nativeLanguage: data.nativeLanguage.present
          ? data.nativeLanguage.value
          : this.nativeLanguage,
      targetLanguage: data.targetLanguage.present
          ? data.targetLanguage.value
          : this.targetLanguage,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Learner(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('name: $name, ')
          ..write('nativeLanguage: $nativeLanguage, ')
          ..write('targetLanguage: $targetLanguage, ')
          ..write('createdAt: $createdAt, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    uuid,
    name,
    nativeLanguage,
    targetLanguage,
    createdAt,
    isActive,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Learner &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.name == this.name &&
          other.nativeLanguage == this.nativeLanguage &&
          other.targetLanguage == this.targetLanguage &&
          other.createdAt == this.createdAt &&
          other.isActive == this.isActive);
}

class LearnersCompanion extends UpdateCompanion<Learner> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<String?> name;
  final Value<String> nativeLanguage;
  final Value<String> targetLanguage;
  final Value<DateTime> createdAt;
  final Value<bool> isActive;
  const LearnersCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.name = const Value.absent(),
    this.nativeLanguage = const Value.absent(),
    this.targetLanguage = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isActive = const Value.absent(),
  });
  LearnersCompanion.insert({
    this.id = const Value.absent(),
    required String uuid,
    this.name = const Value.absent(),
    this.nativeLanguage = const Value.absent(),
    this.targetLanguage = const Value.absent(),
    required DateTime createdAt,
    this.isActive = const Value.absent(),
  }) : uuid = Value(uuid),
       createdAt = Value(createdAt);
  static Insertable<Learner> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<String>? name,
    Expression<String>? nativeLanguage,
    Expression<String>? targetLanguage,
    Expression<DateTime>? createdAt,
    Expression<bool>? isActive,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (name != null) 'name': name,
      if (nativeLanguage != null) 'native_language': nativeLanguage,
      if (targetLanguage != null) 'target_language': targetLanguage,
      if (createdAt != null) 'created_at': createdAt,
      if (isActive != null) 'is_active': isActive,
    });
  }

  LearnersCompanion copyWith({
    Value<int>? id,
    Value<String>? uuid,
    Value<String?>? name,
    Value<String>? nativeLanguage,
    Value<String>? targetLanguage,
    Value<DateTime>? createdAt,
    Value<bool>? isActive,
  }) {
    return LearnersCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      name: name ?? this.name,
      nativeLanguage: nativeLanguage ?? this.nativeLanguage,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (nativeLanguage.present) {
      map['native_language'] = Variable<String>(nativeLanguage.value);
    }
    if (targetLanguage.present) {
      map['target_language'] = Variable<String>(targetLanguage.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LearnersCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('name: $name, ')
          ..write('nativeLanguage: $nativeLanguage, ')
          ..write('targetLanguage: $targetLanguage, ')
          ..write('createdAt: $createdAt, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }
}

class $CourseEnrolmentsTable extends CourseEnrolments
    with TableInfo<$CourseEnrolmentsTable, CourseEnrolment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CourseEnrolmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _learnerIdMeta = const VerificationMeta(
    'learnerId',
  );
  @override
  late final GeneratedColumn<int> learnerId = GeneratedColumn<int>(
    'learner_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES learners (id)',
    ),
  );
  static const VerificationMeta _courseIdMeta = const VerificationMeta(
    'courseId',
  );
  @override
  late final GeneratedColumn<String> courseId = GeneratedColumn<String>(
    'course_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentVersionMeta = const VerificationMeta(
    'contentVersion',
  );
  @override
  late final GeneratedColumn<String> contentVersion = GeneratedColumn<String>(
    'content_version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _enrolledAtMeta = const VerificationMeta(
    'enrolledAt',
  );
  @override
  late final GeneratedColumn<DateTime> enrolledAt = GeneratedColumn<DateTime>(
    'enrolled_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    uuid,
    learnerId,
    courseId,
    contentVersion,
    enrolledAt,
    status,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'course_enrolments';
  @override
  VerificationContext validateIntegrity(
    Insertable<CourseEnrolment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('learner_id')) {
      context.handle(
        _learnerIdMeta,
        learnerId.isAcceptableOrUnknown(data['learner_id']!, _learnerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_learnerIdMeta);
    }
    if (data.containsKey('course_id')) {
      context.handle(
        _courseIdMeta,
        courseId.isAcceptableOrUnknown(data['course_id']!, _courseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_courseIdMeta);
    }
    if (data.containsKey('content_version')) {
      context.handle(
        _contentVersionMeta,
        contentVersion.isAcceptableOrUnknown(
          data['content_version']!,
          _contentVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contentVersionMeta);
    }
    if (data.containsKey('enrolled_at')) {
      context.handle(
        _enrolledAtMeta,
        enrolledAt.isAcceptableOrUnknown(data['enrolled_at']!, _enrolledAtMeta),
      );
    } else if (isInserting) {
      context.missing(_enrolledAtMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CourseEnrolment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CourseEnrolment(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      learnerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}learner_id'],
      )!,
      courseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}course_id'],
      )!,
      contentVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_version'],
      )!,
      enrolledAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}enrolled_at'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
    );
  }

  @override
  $CourseEnrolmentsTable createAlias(String alias) {
    return $CourseEnrolmentsTable(attachedDatabase, alias);
  }
}

class CourseEnrolment extends DataClass implements Insertable<CourseEnrolment> {
  final int id;
  final String uuid;
  final int learnerId;
  final String courseId;
  final String contentVersion;
  final DateTime enrolledAt;
  final String status;
  const CourseEnrolment({
    required this.id,
    required this.uuid,
    required this.learnerId,
    required this.courseId,
    required this.contentVersion,
    required this.enrolledAt,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    map['learner_id'] = Variable<int>(learnerId);
    map['course_id'] = Variable<String>(courseId);
    map['content_version'] = Variable<String>(contentVersion);
    map['enrolled_at'] = Variable<DateTime>(enrolledAt);
    map['status'] = Variable<String>(status);
    return map;
  }

  CourseEnrolmentsCompanion toCompanion(bool nullToAbsent) {
    return CourseEnrolmentsCompanion(
      id: Value(id),
      uuid: Value(uuid),
      learnerId: Value(learnerId),
      courseId: Value(courseId),
      contentVersion: Value(contentVersion),
      enrolledAt: Value(enrolledAt),
      status: Value(status),
    );
  }

  factory CourseEnrolment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CourseEnrolment(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      learnerId: serializer.fromJson<int>(json['learnerId']),
      courseId: serializer.fromJson<String>(json['courseId']),
      contentVersion: serializer.fromJson<String>(json['contentVersion']),
      enrolledAt: serializer.fromJson<DateTime>(json['enrolledAt']),
      status: serializer.fromJson<String>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'learnerId': serializer.toJson<int>(learnerId),
      'courseId': serializer.toJson<String>(courseId),
      'contentVersion': serializer.toJson<String>(contentVersion),
      'enrolledAt': serializer.toJson<DateTime>(enrolledAt),
      'status': serializer.toJson<String>(status),
    };
  }

  CourseEnrolment copyWith({
    int? id,
    String? uuid,
    int? learnerId,
    String? courseId,
    String? contentVersion,
    DateTime? enrolledAt,
    String? status,
  }) => CourseEnrolment(
    id: id ?? this.id,
    uuid: uuid ?? this.uuid,
    learnerId: learnerId ?? this.learnerId,
    courseId: courseId ?? this.courseId,
    contentVersion: contentVersion ?? this.contentVersion,
    enrolledAt: enrolledAt ?? this.enrolledAt,
    status: status ?? this.status,
  );
  CourseEnrolment copyWithCompanion(CourseEnrolmentsCompanion data) {
    return CourseEnrolment(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      learnerId: data.learnerId.present ? data.learnerId.value : this.learnerId,
      courseId: data.courseId.present ? data.courseId.value : this.courseId,
      contentVersion: data.contentVersion.present
          ? data.contentVersion.value
          : this.contentVersion,
      enrolledAt: data.enrolledAt.present
          ? data.enrolledAt.value
          : this.enrolledAt,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CourseEnrolment(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('learnerId: $learnerId, ')
          ..write('courseId: $courseId, ')
          ..write('contentVersion: $contentVersion, ')
          ..write('enrolledAt: $enrolledAt, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    uuid,
    learnerId,
    courseId,
    contentVersion,
    enrolledAt,
    status,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CourseEnrolment &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.learnerId == this.learnerId &&
          other.courseId == this.courseId &&
          other.contentVersion == this.contentVersion &&
          other.enrolledAt == this.enrolledAt &&
          other.status == this.status);
}

class CourseEnrolmentsCompanion extends UpdateCompanion<CourseEnrolment> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<int> learnerId;
  final Value<String> courseId;
  final Value<String> contentVersion;
  final Value<DateTime> enrolledAt;
  final Value<String> status;
  const CourseEnrolmentsCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.learnerId = const Value.absent(),
    this.courseId = const Value.absent(),
    this.contentVersion = const Value.absent(),
    this.enrolledAt = const Value.absent(),
    this.status = const Value.absent(),
  });
  CourseEnrolmentsCompanion.insert({
    this.id = const Value.absent(),
    required String uuid,
    required int learnerId,
    required String courseId,
    required String contentVersion,
    required DateTime enrolledAt,
    required String status,
  }) : uuid = Value(uuid),
       learnerId = Value(learnerId),
       courseId = Value(courseId),
       contentVersion = Value(contentVersion),
       enrolledAt = Value(enrolledAt),
       status = Value(status);
  static Insertable<CourseEnrolment> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<int>? learnerId,
    Expression<String>? courseId,
    Expression<String>? contentVersion,
    Expression<DateTime>? enrolledAt,
    Expression<String>? status,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (learnerId != null) 'learner_id': learnerId,
      if (courseId != null) 'course_id': courseId,
      if (contentVersion != null) 'content_version': contentVersion,
      if (enrolledAt != null) 'enrolled_at': enrolledAt,
      if (status != null) 'status': status,
    });
  }

  CourseEnrolmentsCompanion copyWith({
    Value<int>? id,
    Value<String>? uuid,
    Value<int>? learnerId,
    Value<String>? courseId,
    Value<String>? contentVersion,
    Value<DateTime>? enrolledAt,
    Value<String>? status,
  }) {
    return CourseEnrolmentsCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      learnerId: learnerId ?? this.learnerId,
      courseId: courseId ?? this.courseId,
      contentVersion: contentVersion ?? this.contentVersion,
      enrolledAt: enrolledAt ?? this.enrolledAt,
      status: status ?? this.status,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (learnerId.present) {
      map['learner_id'] = Variable<int>(learnerId.value);
    }
    if (courseId.present) {
      map['course_id'] = Variable<String>(courseId.value);
    }
    if (contentVersion.present) {
      map['content_version'] = Variable<String>(contentVersion.value);
    }
    if (enrolledAt.present) {
      map['enrolled_at'] = Variable<DateTime>(enrolledAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CourseEnrolmentsCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('learnerId: $learnerId, ')
          ..write('courseId: $courseId, ')
          ..write('contentVersion: $contentVersion, ')
          ..write('enrolledAt: $enrolledAt, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }
}

class $UnitProgressTable extends UnitProgress
    with TableInfo<$UnitProgressTable, UnitProgressData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UnitProgressTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _learnerIdMeta = const VerificationMeta(
    'learnerId',
  );
  @override
  late final GeneratedColumn<int> learnerId = GeneratedColumn<int>(
    'learner_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES learners (id)',
    ),
  );
  static const VerificationMeta _unitIdMeta = const VerificationMeta('unitId');
  @override
  late final GeneratedColumn<String> unitId = GeneratedColumn<String>(
    'unit_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastActivityAtMeta = const VerificationMeta(
    'lastActivityAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastActivityAt =
      GeneratedColumn<DateTime>(
        'last_activity_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _masteredAtMeta = const VerificationMeta(
    'masteredAt',
  );
  @override
  late final GeneratedColumn<DateTime> masteredAt = GeneratedColumn<DateTime>(
    'mastered_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isContentStaleMeta = const VerificationMeta(
    'isContentStale',
  );
  @override
  late final GeneratedColumn<bool> isContentStale = GeneratedColumn<bool>(
    'is_content_stale',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_content_stale" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    uuid,
    learnerId,
    unitId,
    state,
    lastActivityAt,
    masteredAt,
    isContentStale,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'unit_progress';
  @override
  VerificationContext validateIntegrity(
    Insertable<UnitProgressData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('learner_id')) {
      context.handle(
        _learnerIdMeta,
        learnerId.isAcceptableOrUnknown(data['learner_id']!, _learnerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_learnerIdMeta);
    }
    if (data.containsKey('unit_id')) {
      context.handle(
        _unitIdMeta,
        unitId.isAcceptableOrUnknown(data['unit_id']!, _unitIdMeta),
      );
    } else if (isInserting) {
      context.missing(_unitIdMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    if (data.containsKey('last_activity_at')) {
      context.handle(
        _lastActivityAtMeta,
        lastActivityAt.isAcceptableOrUnknown(
          data['last_activity_at']!,
          _lastActivityAtMeta,
        ),
      );
    }
    if (data.containsKey('mastered_at')) {
      context.handle(
        _masteredAtMeta,
        masteredAt.isAcceptableOrUnknown(data['mastered_at']!, _masteredAtMeta),
      );
    }
    if (data.containsKey('is_content_stale')) {
      context.handle(
        _isContentStaleMeta,
        isContentStale.isAcceptableOrUnknown(
          data['is_content_stale']!,
          _isContentStaleMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UnitProgressData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UnitProgressData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      learnerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}learner_id'],
      )!,
      unitId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit_id'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      lastActivityAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_activity_at'],
      ),
      masteredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}mastered_at'],
      ),
      isContentStale: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_content_stale'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $UnitProgressTable createAlias(String alias) {
    return $UnitProgressTable(attachedDatabase, alias);
  }
}

class UnitProgressData extends DataClass
    implements Insertable<UnitProgressData> {
  final int id;
  final String uuid;
  final int learnerId;
  final String unitId;
  final String state;
  final DateTime? lastActivityAt;
  final DateTime? masteredAt;
  final bool isContentStale;
  final DateTime updatedAt;
  const UnitProgressData({
    required this.id,
    required this.uuid,
    required this.learnerId,
    required this.unitId,
    required this.state,
    this.lastActivityAt,
    this.masteredAt,
    required this.isContentStale,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    map['learner_id'] = Variable<int>(learnerId);
    map['unit_id'] = Variable<String>(unitId);
    map['state'] = Variable<String>(state);
    if (!nullToAbsent || lastActivityAt != null) {
      map['last_activity_at'] = Variable<DateTime>(lastActivityAt);
    }
    if (!nullToAbsent || masteredAt != null) {
      map['mastered_at'] = Variable<DateTime>(masteredAt);
    }
    map['is_content_stale'] = Variable<bool>(isContentStale);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  UnitProgressCompanion toCompanion(bool nullToAbsent) {
    return UnitProgressCompanion(
      id: Value(id),
      uuid: Value(uuid),
      learnerId: Value(learnerId),
      unitId: Value(unitId),
      state: Value(state),
      lastActivityAt: lastActivityAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastActivityAt),
      masteredAt: masteredAt == null && nullToAbsent
          ? const Value.absent()
          : Value(masteredAt),
      isContentStale: Value(isContentStale),
      updatedAt: Value(updatedAt),
    );
  }

  factory UnitProgressData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UnitProgressData(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      learnerId: serializer.fromJson<int>(json['learnerId']),
      unitId: serializer.fromJson<String>(json['unitId']),
      state: serializer.fromJson<String>(json['state']),
      lastActivityAt: serializer.fromJson<DateTime?>(json['lastActivityAt']),
      masteredAt: serializer.fromJson<DateTime?>(json['masteredAt']),
      isContentStale: serializer.fromJson<bool>(json['isContentStale']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'learnerId': serializer.toJson<int>(learnerId),
      'unitId': serializer.toJson<String>(unitId),
      'state': serializer.toJson<String>(state),
      'lastActivityAt': serializer.toJson<DateTime?>(lastActivityAt),
      'masteredAt': serializer.toJson<DateTime?>(masteredAt),
      'isContentStale': serializer.toJson<bool>(isContentStale),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  UnitProgressData copyWith({
    int? id,
    String? uuid,
    int? learnerId,
    String? unitId,
    String? state,
    Value<DateTime?> lastActivityAt = const Value.absent(),
    Value<DateTime?> masteredAt = const Value.absent(),
    bool? isContentStale,
    DateTime? updatedAt,
  }) => UnitProgressData(
    id: id ?? this.id,
    uuid: uuid ?? this.uuid,
    learnerId: learnerId ?? this.learnerId,
    unitId: unitId ?? this.unitId,
    state: state ?? this.state,
    lastActivityAt: lastActivityAt.present
        ? lastActivityAt.value
        : this.lastActivityAt,
    masteredAt: masteredAt.present ? masteredAt.value : this.masteredAt,
    isContentStale: isContentStale ?? this.isContentStale,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  UnitProgressData copyWithCompanion(UnitProgressCompanion data) {
    return UnitProgressData(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      learnerId: data.learnerId.present ? data.learnerId.value : this.learnerId,
      unitId: data.unitId.present ? data.unitId.value : this.unitId,
      state: data.state.present ? data.state.value : this.state,
      lastActivityAt: data.lastActivityAt.present
          ? data.lastActivityAt.value
          : this.lastActivityAt,
      masteredAt: data.masteredAt.present
          ? data.masteredAt.value
          : this.masteredAt,
      isContentStale: data.isContentStale.present
          ? data.isContentStale.value
          : this.isContentStale,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UnitProgressData(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('learnerId: $learnerId, ')
          ..write('unitId: $unitId, ')
          ..write('state: $state, ')
          ..write('lastActivityAt: $lastActivityAt, ')
          ..write('masteredAt: $masteredAt, ')
          ..write('isContentStale: $isContentStale, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    uuid,
    learnerId,
    unitId,
    state,
    lastActivityAt,
    masteredAt,
    isContentStale,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UnitProgressData &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.learnerId == this.learnerId &&
          other.unitId == this.unitId &&
          other.state == this.state &&
          other.lastActivityAt == this.lastActivityAt &&
          other.masteredAt == this.masteredAt &&
          other.isContentStale == this.isContentStale &&
          other.updatedAt == this.updatedAt);
}

class UnitProgressCompanion extends UpdateCompanion<UnitProgressData> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<int> learnerId;
  final Value<String> unitId;
  final Value<String> state;
  final Value<DateTime?> lastActivityAt;
  final Value<DateTime?> masteredAt;
  final Value<bool> isContentStale;
  final Value<DateTime> updatedAt;
  const UnitProgressCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.learnerId = const Value.absent(),
    this.unitId = const Value.absent(),
    this.state = const Value.absent(),
    this.lastActivityAt = const Value.absent(),
    this.masteredAt = const Value.absent(),
    this.isContentStale = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  UnitProgressCompanion.insert({
    this.id = const Value.absent(),
    required String uuid,
    required int learnerId,
    required String unitId,
    required String state,
    this.lastActivityAt = const Value.absent(),
    this.masteredAt = const Value.absent(),
    this.isContentStale = const Value.absent(),
    required DateTime updatedAt,
  }) : uuid = Value(uuid),
       learnerId = Value(learnerId),
       unitId = Value(unitId),
       state = Value(state),
       updatedAt = Value(updatedAt);
  static Insertable<UnitProgressData> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<int>? learnerId,
    Expression<String>? unitId,
    Expression<String>? state,
    Expression<DateTime>? lastActivityAt,
    Expression<DateTime>? masteredAt,
    Expression<bool>? isContentStale,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (learnerId != null) 'learner_id': learnerId,
      if (unitId != null) 'unit_id': unitId,
      if (state != null) 'state': state,
      if (lastActivityAt != null) 'last_activity_at': lastActivityAt,
      if (masteredAt != null) 'mastered_at': masteredAt,
      if (isContentStale != null) 'is_content_stale': isContentStale,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  UnitProgressCompanion copyWith({
    Value<int>? id,
    Value<String>? uuid,
    Value<int>? learnerId,
    Value<String>? unitId,
    Value<String>? state,
    Value<DateTime?>? lastActivityAt,
    Value<DateTime?>? masteredAt,
    Value<bool>? isContentStale,
    Value<DateTime>? updatedAt,
  }) {
    return UnitProgressCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      learnerId: learnerId ?? this.learnerId,
      unitId: unitId ?? this.unitId,
      state: state ?? this.state,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      masteredAt: masteredAt ?? this.masteredAt,
      isContentStale: isContentStale ?? this.isContentStale,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (learnerId.present) {
      map['learner_id'] = Variable<int>(learnerId.value);
    }
    if (unitId.present) {
      map['unit_id'] = Variable<String>(unitId.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (lastActivityAt.present) {
      map['last_activity_at'] = Variable<DateTime>(lastActivityAt.value);
    }
    if (masteredAt.present) {
      map['mastered_at'] = Variable<DateTime>(masteredAt.value);
    }
    if (isContentStale.present) {
      map['is_content_stale'] = Variable<bool>(isContentStale.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UnitProgressCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('learnerId: $learnerId, ')
          ..write('unitId: $unitId, ')
          ..write('state: $state, ')
          ..write('lastActivityAt: $lastActivityAt, ')
          ..write('masteredAt: $masteredAt, ')
          ..write('isContentStale: $isContentStale, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $LessonProgressTable extends LessonProgress
    with TableInfo<$LessonProgressTable, LessonProgressData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LessonProgressTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _learnerIdMeta = const VerificationMeta(
    'learnerId',
  );
  @override
  late final GeneratedColumn<int> learnerId = GeneratedColumn<int>(
    'learner_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES learners (id)',
    ),
  );
  static const VerificationMeta _lessonIdMeta = const VerificationMeta(
    'lessonId',
  );
  @override
  late final GeneratedColumn<String> lessonId = GeneratedColumn<String>(
    'lesson_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitIdMeta = const VerificationMeta('unitId');
  @override
  late final GeneratedColumn<String> unitId = GeneratedColumn<String>(
    'unit_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastActivityIdMeta = const VerificationMeta(
    'lastActivityId',
  );
  @override
  late final GeneratedColumn<String> lastActivityId = GeneratedColumn<String>(
    'last_activity_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastPositionUpdatedAtMeta =
      const VerificationMeta('lastPositionUpdatedAt');
  @override
  late final GeneratedColumn<DateTime> lastPositionUpdatedAt =
      GeneratedColumn<DateTime>(
        'last_position_updated_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    uuid,
    learnerId,
    lessonId,
    unitId,
    state,
    lastActivityId,
    lastPositionUpdatedAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lesson_progress';
  @override
  VerificationContext validateIntegrity(
    Insertable<LessonProgressData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('learner_id')) {
      context.handle(
        _learnerIdMeta,
        learnerId.isAcceptableOrUnknown(data['learner_id']!, _learnerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_learnerIdMeta);
    }
    if (data.containsKey('lesson_id')) {
      context.handle(
        _lessonIdMeta,
        lessonId.isAcceptableOrUnknown(data['lesson_id']!, _lessonIdMeta),
      );
    } else if (isInserting) {
      context.missing(_lessonIdMeta);
    }
    if (data.containsKey('unit_id')) {
      context.handle(
        _unitIdMeta,
        unitId.isAcceptableOrUnknown(data['unit_id']!, _unitIdMeta),
      );
    } else if (isInserting) {
      context.missing(_unitIdMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    if (data.containsKey('last_activity_id')) {
      context.handle(
        _lastActivityIdMeta,
        lastActivityId.isAcceptableOrUnknown(
          data['last_activity_id']!,
          _lastActivityIdMeta,
        ),
      );
    }
    if (data.containsKey('last_position_updated_at')) {
      context.handle(
        _lastPositionUpdatedAtMeta,
        lastPositionUpdatedAt.isAcceptableOrUnknown(
          data['last_position_updated_at']!,
          _lastPositionUpdatedAtMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LessonProgressData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LessonProgressData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      learnerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}learner_id'],
      )!,
      lessonId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lesson_id'],
      )!,
      unitId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit_id'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      lastActivityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_activity_id'],
      ),
      lastPositionUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_position_updated_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LessonProgressTable createAlias(String alias) {
    return $LessonProgressTable(attachedDatabase, alias);
  }
}

class LessonProgressData extends DataClass
    implements Insertable<LessonProgressData> {
  final int id;
  final String uuid;
  final int learnerId;
  final String lessonId;
  final String unitId;
  final String state;
  final String? lastActivityId;
  final DateTime? lastPositionUpdatedAt;
  final DateTime updatedAt;
  const LessonProgressData({
    required this.id,
    required this.uuid,
    required this.learnerId,
    required this.lessonId,
    required this.unitId,
    required this.state,
    this.lastActivityId,
    this.lastPositionUpdatedAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    map['learner_id'] = Variable<int>(learnerId);
    map['lesson_id'] = Variable<String>(lessonId);
    map['unit_id'] = Variable<String>(unitId);
    map['state'] = Variable<String>(state);
    if (!nullToAbsent || lastActivityId != null) {
      map['last_activity_id'] = Variable<String>(lastActivityId);
    }
    if (!nullToAbsent || lastPositionUpdatedAt != null) {
      map['last_position_updated_at'] = Variable<DateTime>(
        lastPositionUpdatedAt,
      );
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LessonProgressCompanion toCompanion(bool nullToAbsent) {
    return LessonProgressCompanion(
      id: Value(id),
      uuid: Value(uuid),
      learnerId: Value(learnerId),
      lessonId: Value(lessonId),
      unitId: Value(unitId),
      state: Value(state),
      lastActivityId: lastActivityId == null && nullToAbsent
          ? const Value.absent()
          : Value(lastActivityId),
      lastPositionUpdatedAt: lastPositionUpdatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPositionUpdatedAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory LessonProgressData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LessonProgressData(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      learnerId: serializer.fromJson<int>(json['learnerId']),
      lessonId: serializer.fromJson<String>(json['lessonId']),
      unitId: serializer.fromJson<String>(json['unitId']),
      state: serializer.fromJson<String>(json['state']),
      lastActivityId: serializer.fromJson<String?>(json['lastActivityId']),
      lastPositionUpdatedAt: serializer.fromJson<DateTime?>(
        json['lastPositionUpdatedAt'],
      ),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'learnerId': serializer.toJson<int>(learnerId),
      'lessonId': serializer.toJson<String>(lessonId),
      'unitId': serializer.toJson<String>(unitId),
      'state': serializer.toJson<String>(state),
      'lastActivityId': serializer.toJson<String?>(lastActivityId),
      'lastPositionUpdatedAt': serializer.toJson<DateTime?>(
        lastPositionUpdatedAt,
      ),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LessonProgressData copyWith({
    int? id,
    String? uuid,
    int? learnerId,
    String? lessonId,
    String? unitId,
    String? state,
    Value<String?> lastActivityId = const Value.absent(),
    Value<DateTime?> lastPositionUpdatedAt = const Value.absent(),
    DateTime? updatedAt,
  }) => LessonProgressData(
    id: id ?? this.id,
    uuid: uuid ?? this.uuid,
    learnerId: learnerId ?? this.learnerId,
    lessonId: lessonId ?? this.lessonId,
    unitId: unitId ?? this.unitId,
    state: state ?? this.state,
    lastActivityId: lastActivityId.present
        ? lastActivityId.value
        : this.lastActivityId,
    lastPositionUpdatedAt: lastPositionUpdatedAt.present
        ? lastPositionUpdatedAt.value
        : this.lastPositionUpdatedAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LessonProgressData copyWithCompanion(LessonProgressCompanion data) {
    return LessonProgressData(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      learnerId: data.learnerId.present ? data.learnerId.value : this.learnerId,
      lessonId: data.lessonId.present ? data.lessonId.value : this.lessonId,
      unitId: data.unitId.present ? data.unitId.value : this.unitId,
      state: data.state.present ? data.state.value : this.state,
      lastActivityId: data.lastActivityId.present
          ? data.lastActivityId.value
          : this.lastActivityId,
      lastPositionUpdatedAt: data.lastPositionUpdatedAt.present
          ? data.lastPositionUpdatedAt.value
          : this.lastPositionUpdatedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LessonProgressData(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('learnerId: $learnerId, ')
          ..write('lessonId: $lessonId, ')
          ..write('unitId: $unitId, ')
          ..write('state: $state, ')
          ..write('lastActivityId: $lastActivityId, ')
          ..write('lastPositionUpdatedAt: $lastPositionUpdatedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    uuid,
    learnerId,
    lessonId,
    unitId,
    state,
    lastActivityId,
    lastPositionUpdatedAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LessonProgressData &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.learnerId == this.learnerId &&
          other.lessonId == this.lessonId &&
          other.unitId == this.unitId &&
          other.state == this.state &&
          other.lastActivityId == this.lastActivityId &&
          other.lastPositionUpdatedAt == this.lastPositionUpdatedAt &&
          other.updatedAt == this.updatedAt);
}

class LessonProgressCompanion extends UpdateCompanion<LessonProgressData> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<int> learnerId;
  final Value<String> lessonId;
  final Value<String> unitId;
  final Value<String> state;
  final Value<String?> lastActivityId;
  final Value<DateTime?> lastPositionUpdatedAt;
  final Value<DateTime> updatedAt;
  const LessonProgressCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.learnerId = const Value.absent(),
    this.lessonId = const Value.absent(),
    this.unitId = const Value.absent(),
    this.state = const Value.absent(),
    this.lastActivityId = const Value.absent(),
    this.lastPositionUpdatedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  LessonProgressCompanion.insert({
    this.id = const Value.absent(),
    required String uuid,
    required int learnerId,
    required String lessonId,
    required String unitId,
    required String state,
    this.lastActivityId = const Value.absent(),
    this.lastPositionUpdatedAt = const Value.absent(),
    required DateTime updatedAt,
  }) : uuid = Value(uuid),
       learnerId = Value(learnerId),
       lessonId = Value(lessonId),
       unitId = Value(unitId),
       state = Value(state),
       updatedAt = Value(updatedAt);
  static Insertable<LessonProgressData> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<int>? learnerId,
    Expression<String>? lessonId,
    Expression<String>? unitId,
    Expression<String>? state,
    Expression<String>? lastActivityId,
    Expression<DateTime>? lastPositionUpdatedAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (learnerId != null) 'learner_id': learnerId,
      if (lessonId != null) 'lesson_id': lessonId,
      if (unitId != null) 'unit_id': unitId,
      if (state != null) 'state': state,
      if (lastActivityId != null) 'last_activity_id': lastActivityId,
      if (lastPositionUpdatedAt != null)
        'last_position_updated_at': lastPositionUpdatedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  LessonProgressCompanion copyWith({
    Value<int>? id,
    Value<String>? uuid,
    Value<int>? learnerId,
    Value<String>? lessonId,
    Value<String>? unitId,
    Value<String>? state,
    Value<String?>? lastActivityId,
    Value<DateTime?>? lastPositionUpdatedAt,
    Value<DateTime>? updatedAt,
  }) {
    return LessonProgressCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      learnerId: learnerId ?? this.learnerId,
      lessonId: lessonId ?? this.lessonId,
      unitId: unitId ?? this.unitId,
      state: state ?? this.state,
      lastActivityId: lastActivityId ?? this.lastActivityId,
      lastPositionUpdatedAt:
          lastPositionUpdatedAt ?? this.lastPositionUpdatedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (learnerId.present) {
      map['learner_id'] = Variable<int>(learnerId.value);
    }
    if (lessonId.present) {
      map['lesson_id'] = Variable<String>(lessonId.value);
    }
    if (unitId.present) {
      map['unit_id'] = Variable<String>(unitId.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (lastActivityId.present) {
      map['last_activity_id'] = Variable<String>(lastActivityId.value);
    }
    if (lastPositionUpdatedAt.present) {
      map['last_position_updated_at'] = Variable<DateTime>(
        lastPositionUpdatedAt.value,
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LessonProgressCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('learnerId: $learnerId, ')
          ..write('lessonId: $lessonId, ')
          ..write('unitId: $unitId, ')
          ..write('state: $state, ')
          ..write('lastActivityId: $lastActivityId, ')
          ..write('lastPositionUpdatedAt: $lastPositionUpdatedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $ActivityAttemptsTable extends ActivityAttempts
    with TableInfo<$ActivityAttemptsTable, ActivityAttempt> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ActivityAttemptsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _learnerIdMeta = const VerificationMeta(
    'learnerId',
  );
  @override
  late final GeneratedColumn<int> learnerId = GeneratedColumn<int>(
    'learner_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES learners (id)',
    ),
  );
  static const VerificationMeta _activityIdMeta = const VerificationMeta(
    'activityId',
  );
  @override
  late final GeneratedColumn<String> activityId = GeneratedColumn<String>(
    'activity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lessonIdMeta = const VerificationMeta(
    'lessonId',
  );
  @override
  late final GeneratedColumn<String> lessonId = GeneratedColumn<String>(
    'lesson_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sessionTypeMeta = const VerificationMeta(
    'sessionType',
  );
  @override
  late final GeneratedColumn<String> sessionType = GeneratedColumn<String>(
    'session_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _modeMeta = const VerificationMeta('mode');
  @override
  late final GeneratedColumn<String> mode = GeneratedColumn<String>(
    'mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _evidenceSkillMeta = const VerificationMeta(
    'evidenceSkill',
  );
  @override
  late final GeneratedColumn<String> evidenceSkill = GeneratedColumn<String>(
    'evidence_skill',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rawAnswerMeta = const VerificationMeta(
    'rawAnswer',
  );
  @override
  late final GeneratedColumn<String> rawAnswer = GeneratedColumn<String>(
    'raw_answer',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isCorrectMeta = const VerificationMeta(
    'isCorrect',
  );
  @override
  late final GeneratedColumn<bool> isCorrect = GeneratedColumn<bool>(
    'is_correct',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_correct" IN (0, 1))',
    ),
  );
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<double> score = GeneratedColumn<double>(
    'score',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _criteriaScoresMeta = const VerificationMeta(
    'criteriaScores',
  );
  @override
  late final GeneratedColumn<String> criteriaScores = GeneratedColumn<String>(
    'criteria_scores',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _wasFallbackMeta = const VerificationMeta(
    'wasFallback',
  );
  @override
  late final GeneratedColumn<bool> wasFallback = GeneratedColumn<bool>(
    'was_fallback',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("was_fallback" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _attemptedAtMeta = const VerificationMeta(
    'attemptedAt',
  );
  @override
  late final GeneratedColumn<DateTime> attemptedAt = GeneratedColumn<DateTime>(
    'attempted_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    uuid,
    learnerId,
    activityId,
    lessonId,
    sessionType,
    sessionId,
    mode,
    evidenceSkill,
    rawAnswer,
    isCorrect,
    score,
    criteriaScores,
    wasFallback,
    attemptedAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'activity_attempts';
  @override
  VerificationContext validateIntegrity(
    Insertable<ActivityAttempt> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('learner_id')) {
      context.handle(
        _learnerIdMeta,
        learnerId.isAcceptableOrUnknown(data['learner_id']!, _learnerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_learnerIdMeta);
    }
    if (data.containsKey('activity_id')) {
      context.handle(
        _activityIdMeta,
        activityId.isAcceptableOrUnknown(data['activity_id']!, _activityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_activityIdMeta);
    }
    if (data.containsKey('lesson_id')) {
      context.handle(
        _lessonIdMeta,
        lessonId.isAcceptableOrUnknown(data['lesson_id']!, _lessonIdMeta),
      );
    }
    if (data.containsKey('session_type')) {
      context.handle(
        _sessionTypeMeta,
        sessionType.isAcceptableOrUnknown(
          data['session_type']!,
          _sessionTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sessionTypeMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    }
    if (data.containsKey('mode')) {
      context.handle(
        _modeMeta,
        mode.isAcceptableOrUnknown(data['mode']!, _modeMeta),
      );
    } else if (isInserting) {
      context.missing(_modeMeta);
    }
    if (data.containsKey('evidence_skill')) {
      context.handle(
        _evidenceSkillMeta,
        evidenceSkill.isAcceptableOrUnknown(
          data['evidence_skill']!,
          _evidenceSkillMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_evidenceSkillMeta);
    }
    if (data.containsKey('raw_answer')) {
      context.handle(
        _rawAnswerMeta,
        rawAnswer.isAcceptableOrUnknown(data['raw_answer']!, _rawAnswerMeta),
      );
    }
    if (data.containsKey('is_correct')) {
      context.handle(
        _isCorrectMeta,
        isCorrect.isAcceptableOrUnknown(data['is_correct']!, _isCorrectMeta),
      );
    }
    if (data.containsKey('score')) {
      context.handle(
        _scoreMeta,
        score.isAcceptableOrUnknown(data['score']!, _scoreMeta),
      );
    }
    if (data.containsKey('criteria_scores')) {
      context.handle(
        _criteriaScoresMeta,
        criteriaScores.isAcceptableOrUnknown(
          data['criteria_scores']!,
          _criteriaScoresMeta,
        ),
      );
    }
    if (data.containsKey('was_fallback')) {
      context.handle(
        _wasFallbackMeta,
        wasFallback.isAcceptableOrUnknown(
          data['was_fallback']!,
          _wasFallbackMeta,
        ),
      );
    }
    if (data.containsKey('attempted_at')) {
      context.handle(
        _attemptedAtMeta,
        attemptedAt.isAcceptableOrUnknown(
          data['attempted_at']!,
          _attemptedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_attemptedAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ActivityAttempt map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ActivityAttempt(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      learnerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}learner_id'],
      )!,
      activityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}activity_id'],
      )!,
      lessonId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lesson_id'],
      ),
      sessionType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_type'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      ),
      mode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mode'],
      )!,
      evidenceSkill: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}evidence_skill'],
      )!,
      rawAnswer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_answer'],
      ),
      isCorrect: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_correct'],
      ),
      score: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}score'],
      ),
      criteriaScores: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}criteria_scores'],
      ),
      wasFallback: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}was_fallback'],
      )!,
      attemptedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}attempted_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ActivityAttemptsTable createAlias(String alias) {
    return $ActivityAttemptsTable(attachedDatabase, alias);
  }
}

class ActivityAttempt extends DataClass implements Insertable<ActivityAttempt> {
  final int id;
  final String uuid;
  final int learnerId;
  final String activityId;
  final String? lessonId;
  final String sessionType;
  final String? sessionId;
  final String mode;
  final String evidenceSkill;
  final String? rawAnswer;
  final bool? isCorrect;
  final double? score;
  final String? criteriaScores;
  final bool wasFallback;
  final DateTime attemptedAt;
  final DateTime updatedAt;
  const ActivityAttempt({
    required this.id,
    required this.uuid,
    required this.learnerId,
    required this.activityId,
    this.lessonId,
    required this.sessionType,
    this.sessionId,
    required this.mode,
    required this.evidenceSkill,
    this.rawAnswer,
    this.isCorrect,
    this.score,
    this.criteriaScores,
    required this.wasFallback,
    required this.attemptedAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    map['learner_id'] = Variable<int>(learnerId);
    map['activity_id'] = Variable<String>(activityId);
    if (!nullToAbsent || lessonId != null) {
      map['lesson_id'] = Variable<String>(lessonId);
    }
    map['session_type'] = Variable<String>(sessionType);
    if (!nullToAbsent || sessionId != null) {
      map['session_id'] = Variable<String>(sessionId);
    }
    map['mode'] = Variable<String>(mode);
    map['evidence_skill'] = Variable<String>(evidenceSkill);
    if (!nullToAbsent || rawAnswer != null) {
      map['raw_answer'] = Variable<String>(rawAnswer);
    }
    if (!nullToAbsent || isCorrect != null) {
      map['is_correct'] = Variable<bool>(isCorrect);
    }
    if (!nullToAbsent || score != null) {
      map['score'] = Variable<double>(score);
    }
    if (!nullToAbsent || criteriaScores != null) {
      map['criteria_scores'] = Variable<String>(criteriaScores);
    }
    map['was_fallback'] = Variable<bool>(wasFallback);
    map['attempted_at'] = Variable<DateTime>(attemptedAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ActivityAttemptsCompanion toCompanion(bool nullToAbsent) {
    return ActivityAttemptsCompanion(
      id: Value(id),
      uuid: Value(uuid),
      learnerId: Value(learnerId),
      activityId: Value(activityId),
      lessonId: lessonId == null && nullToAbsent
          ? const Value.absent()
          : Value(lessonId),
      sessionType: Value(sessionType),
      sessionId: sessionId == null && nullToAbsent
          ? const Value.absent()
          : Value(sessionId),
      mode: Value(mode),
      evidenceSkill: Value(evidenceSkill),
      rawAnswer: rawAnswer == null && nullToAbsent
          ? const Value.absent()
          : Value(rawAnswer),
      isCorrect: isCorrect == null && nullToAbsent
          ? const Value.absent()
          : Value(isCorrect),
      score: score == null && nullToAbsent
          ? const Value.absent()
          : Value(score),
      criteriaScores: criteriaScores == null && nullToAbsent
          ? const Value.absent()
          : Value(criteriaScores),
      wasFallback: Value(wasFallback),
      attemptedAt: Value(attemptedAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ActivityAttempt.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ActivityAttempt(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      learnerId: serializer.fromJson<int>(json['learnerId']),
      activityId: serializer.fromJson<String>(json['activityId']),
      lessonId: serializer.fromJson<String?>(json['lessonId']),
      sessionType: serializer.fromJson<String>(json['sessionType']),
      sessionId: serializer.fromJson<String?>(json['sessionId']),
      mode: serializer.fromJson<String>(json['mode']),
      evidenceSkill: serializer.fromJson<String>(json['evidenceSkill']),
      rawAnswer: serializer.fromJson<String?>(json['rawAnswer']),
      isCorrect: serializer.fromJson<bool?>(json['isCorrect']),
      score: serializer.fromJson<double?>(json['score']),
      criteriaScores: serializer.fromJson<String?>(json['criteriaScores']),
      wasFallback: serializer.fromJson<bool>(json['wasFallback']),
      attemptedAt: serializer.fromJson<DateTime>(json['attemptedAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'learnerId': serializer.toJson<int>(learnerId),
      'activityId': serializer.toJson<String>(activityId),
      'lessonId': serializer.toJson<String?>(lessonId),
      'sessionType': serializer.toJson<String>(sessionType),
      'sessionId': serializer.toJson<String?>(sessionId),
      'mode': serializer.toJson<String>(mode),
      'evidenceSkill': serializer.toJson<String>(evidenceSkill),
      'rawAnswer': serializer.toJson<String?>(rawAnswer),
      'isCorrect': serializer.toJson<bool?>(isCorrect),
      'score': serializer.toJson<double?>(score),
      'criteriaScores': serializer.toJson<String?>(criteriaScores),
      'wasFallback': serializer.toJson<bool>(wasFallback),
      'attemptedAt': serializer.toJson<DateTime>(attemptedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ActivityAttempt copyWith({
    int? id,
    String? uuid,
    int? learnerId,
    String? activityId,
    Value<String?> lessonId = const Value.absent(),
    String? sessionType,
    Value<String?> sessionId = const Value.absent(),
    String? mode,
    String? evidenceSkill,
    Value<String?> rawAnswer = const Value.absent(),
    Value<bool?> isCorrect = const Value.absent(),
    Value<double?> score = const Value.absent(),
    Value<String?> criteriaScores = const Value.absent(),
    bool? wasFallback,
    DateTime? attemptedAt,
    DateTime? updatedAt,
  }) => ActivityAttempt(
    id: id ?? this.id,
    uuid: uuid ?? this.uuid,
    learnerId: learnerId ?? this.learnerId,
    activityId: activityId ?? this.activityId,
    lessonId: lessonId.present ? lessonId.value : this.lessonId,
    sessionType: sessionType ?? this.sessionType,
    sessionId: sessionId.present ? sessionId.value : this.sessionId,
    mode: mode ?? this.mode,
    evidenceSkill: evidenceSkill ?? this.evidenceSkill,
    rawAnswer: rawAnswer.present ? rawAnswer.value : this.rawAnswer,
    isCorrect: isCorrect.present ? isCorrect.value : this.isCorrect,
    score: score.present ? score.value : this.score,
    criteriaScores: criteriaScores.present
        ? criteriaScores.value
        : this.criteriaScores,
    wasFallback: wasFallback ?? this.wasFallback,
    attemptedAt: attemptedAt ?? this.attemptedAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ActivityAttempt copyWithCompanion(ActivityAttemptsCompanion data) {
    return ActivityAttempt(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      learnerId: data.learnerId.present ? data.learnerId.value : this.learnerId,
      activityId: data.activityId.present
          ? data.activityId.value
          : this.activityId,
      lessonId: data.lessonId.present ? data.lessonId.value : this.lessonId,
      sessionType: data.sessionType.present
          ? data.sessionType.value
          : this.sessionType,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      mode: data.mode.present ? data.mode.value : this.mode,
      evidenceSkill: data.evidenceSkill.present
          ? data.evidenceSkill.value
          : this.evidenceSkill,
      rawAnswer: data.rawAnswer.present ? data.rawAnswer.value : this.rawAnswer,
      isCorrect: data.isCorrect.present ? data.isCorrect.value : this.isCorrect,
      score: data.score.present ? data.score.value : this.score,
      criteriaScores: data.criteriaScores.present
          ? data.criteriaScores.value
          : this.criteriaScores,
      wasFallback: data.wasFallback.present
          ? data.wasFallback.value
          : this.wasFallback,
      attemptedAt: data.attemptedAt.present
          ? data.attemptedAt.value
          : this.attemptedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ActivityAttempt(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('learnerId: $learnerId, ')
          ..write('activityId: $activityId, ')
          ..write('lessonId: $lessonId, ')
          ..write('sessionType: $sessionType, ')
          ..write('sessionId: $sessionId, ')
          ..write('mode: $mode, ')
          ..write('evidenceSkill: $evidenceSkill, ')
          ..write('rawAnswer: $rawAnswer, ')
          ..write('isCorrect: $isCorrect, ')
          ..write('score: $score, ')
          ..write('criteriaScores: $criteriaScores, ')
          ..write('wasFallback: $wasFallback, ')
          ..write('attemptedAt: $attemptedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    uuid,
    learnerId,
    activityId,
    lessonId,
    sessionType,
    sessionId,
    mode,
    evidenceSkill,
    rawAnswer,
    isCorrect,
    score,
    criteriaScores,
    wasFallback,
    attemptedAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ActivityAttempt &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.learnerId == this.learnerId &&
          other.activityId == this.activityId &&
          other.lessonId == this.lessonId &&
          other.sessionType == this.sessionType &&
          other.sessionId == this.sessionId &&
          other.mode == this.mode &&
          other.evidenceSkill == this.evidenceSkill &&
          other.rawAnswer == this.rawAnswer &&
          other.isCorrect == this.isCorrect &&
          other.score == this.score &&
          other.criteriaScores == this.criteriaScores &&
          other.wasFallback == this.wasFallback &&
          other.attemptedAt == this.attemptedAt &&
          other.updatedAt == this.updatedAt);
}

class ActivityAttemptsCompanion extends UpdateCompanion<ActivityAttempt> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<int> learnerId;
  final Value<String> activityId;
  final Value<String?> lessonId;
  final Value<String> sessionType;
  final Value<String?> sessionId;
  final Value<String> mode;
  final Value<String> evidenceSkill;
  final Value<String?> rawAnswer;
  final Value<bool?> isCorrect;
  final Value<double?> score;
  final Value<String?> criteriaScores;
  final Value<bool> wasFallback;
  final Value<DateTime> attemptedAt;
  final Value<DateTime> updatedAt;
  const ActivityAttemptsCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.learnerId = const Value.absent(),
    this.activityId = const Value.absent(),
    this.lessonId = const Value.absent(),
    this.sessionType = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.mode = const Value.absent(),
    this.evidenceSkill = const Value.absent(),
    this.rawAnswer = const Value.absent(),
    this.isCorrect = const Value.absent(),
    this.score = const Value.absent(),
    this.criteriaScores = const Value.absent(),
    this.wasFallback = const Value.absent(),
    this.attemptedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ActivityAttemptsCompanion.insert({
    this.id = const Value.absent(),
    required String uuid,
    required int learnerId,
    required String activityId,
    this.lessonId = const Value.absent(),
    required String sessionType,
    this.sessionId = const Value.absent(),
    required String mode,
    required String evidenceSkill,
    this.rawAnswer = const Value.absent(),
    this.isCorrect = const Value.absent(),
    this.score = const Value.absent(),
    this.criteriaScores = const Value.absent(),
    this.wasFallback = const Value.absent(),
    required DateTime attemptedAt,
    required DateTime updatedAt,
  }) : uuid = Value(uuid),
       learnerId = Value(learnerId),
       activityId = Value(activityId),
       sessionType = Value(sessionType),
       mode = Value(mode),
       evidenceSkill = Value(evidenceSkill),
       attemptedAt = Value(attemptedAt),
       updatedAt = Value(updatedAt);
  static Insertable<ActivityAttempt> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<int>? learnerId,
    Expression<String>? activityId,
    Expression<String>? lessonId,
    Expression<String>? sessionType,
    Expression<String>? sessionId,
    Expression<String>? mode,
    Expression<String>? evidenceSkill,
    Expression<String>? rawAnswer,
    Expression<bool>? isCorrect,
    Expression<double>? score,
    Expression<String>? criteriaScores,
    Expression<bool>? wasFallback,
    Expression<DateTime>? attemptedAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (learnerId != null) 'learner_id': learnerId,
      if (activityId != null) 'activity_id': activityId,
      if (lessonId != null) 'lesson_id': lessonId,
      if (sessionType != null) 'session_type': sessionType,
      if (sessionId != null) 'session_id': sessionId,
      if (mode != null) 'mode': mode,
      if (evidenceSkill != null) 'evidence_skill': evidenceSkill,
      if (rawAnswer != null) 'raw_answer': rawAnswer,
      if (isCorrect != null) 'is_correct': isCorrect,
      if (score != null) 'score': score,
      if (criteriaScores != null) 'criteria_scores': criteriaScores,
      if (wasFallback != null) 'was_fallback': wasFallback,
      if (attemptedAt != null) 'attempted_at': attemptedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ActivityAttemptsCompanion copyWith({
    Value<int>? id,
    Value<String>? uuid,
    Value<int>? learnerId,
    Value<String>? activityId,
    Value<String?>? lessonId,
    Value<String>? sessionType,
    Value<String?>? sessionId,
    Value<String>? mode,
    Value<String>? evidenceSkill,
    Value<String?>? rawAnswer,
    Value<bool?>? isCorrect,
    Value<double?>? score,
    Value<String?>? criteriaScores,
    Value<bool>? wasFallback,
    Value<DateTime>? attemptedAt,
    Value<DateTime>? updatedAt,
  }) {
    return ActivityAttemptsCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      learnerId: learnerId ?? this.learnerId,
      activityId: activityId ?? this.activityId,
      lessonId: lessonId ?? this.lessonId,
      sessionType: sessionType ?? this.sessionType,
      sessionId: sessionId ?? this.sessionId,
      mode: mode ?? this.mode,
      evidenceSkill: evidenceSkill ?? this.evidenceSkill,
      rawAnswer: rawAnswer ?? this.rawAnswer,
      isCorrect: isCorrect ?? this.isCorrect,
      score: score ?? this.score,
      criteriaScores: criteriaScores ?? this.criteriaScores,
      wasFallback: wasFallback ?? this.wasFallback,
      attemptedAt: attemptedAt ?? this.attemptedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (learnerId.present) {
      map['learner_id'] = Variable<int>(learnerId.value);
    }
    if (activityId.present) {
      map['activity_id'] = Variable<String>(activityId.value);
    }
    if (lessonId.present) {
      map['lesson_id'] = Variable<String>(lessonId.value);
    }
    if (sessionType.present) {
      map['session_type'] = Variable<String>(sessionType.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (mode.present) {
      map['mode'] = Variable<String>(mode.value);
    }
    if (evidenceSkill.present) {
      map['evidence_skill'] = Variable<String>(evidenceSkill.value);
    }
    if (rawAnswer.present) {
      map['raw_answer'] = Variable<String>(rawAnswer.value);
    }
    if (isCorrect.present) {
      map['is_correct'] = Variable<bool>(isCorrect.value);
    }
    if (score.present) {
      map['score'] = Variable<double>(score.value);
    }
    if (criteriaScores.present) {
      map['criteria_scores'] = Variable<String>(criteriaScores.value);
    }
    if (wasFallback.present) {
      map['was_fallback'] = Variable<bool>(wasFallback.value);
    }
    if (attemptedAt.present) {
      map['attempted_at'] = Variable<DateTime>(attemptedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ActivityAttemptsCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('learnerId: $learnerId, ')
          ..write('activityId: $activityId, ')
          ..write('lessonId: $lessonId, ')
          ..write('sessionType: $sessionType, ')
          ..write('sessionId: $sessionId, ')
          ..write('mode: $mode, ')
          ..write('evidenceSkill: $evidenceSkill, ')
          ..write('rawAnswer: $rawAnswer, ')
          ..write('isCorrect: $isCorrect, ')
          ..write('score: $score, ')
          ..write('criteriaScores: $criteriaScores, ')
          ..write('wasFallback: $wasFallback, ')
          ..write('attemptedAt: $attemptedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $ActivityAttemptCanDosTable extends ActivityAttemptCanDos
    with TableInfo<$ActivityAttemptCanDosTable, ActivityAttemptCanDo> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ActivityAttemptCanDosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _attemptIdMeta = const VerificationMeta(
    'attemptId',
  );
  @override
  late final GeneratedColumn<int> attemptId = GeneratedColumn<int>(
    'attempt_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES activity_attempts (id)',
    ),
  );
  static const VerificationMeta _canDoIdMeta = const VerificationMeta(
    'canDoId',
  );
  @override
  late final GeneratedColumn<String> canDoId = GeneratedColumn<String>(
    'can_do_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, attemptId, canDoId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'activity_attempt_can_dos';
  @override
  VerificationContext validateIntegrity(
    Insertable<ActivityAttemptCanDo> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('attempt_id')) {
      context.handle(
        _attemptIdMeta,
        attemptId.isAcceptableOrUnknown(data['attempt_id']!, _attemptIdMeta),
      );
    } else if (isInserting) {
      context.missing(_attemptIdMeta);
    }
    if (data.containsKey('can_do_id')) {
      context.handle(
        _canDoIdMeta,
        canDoId.isAcceptableOrUnknown(data['can_do_id']!, _canDoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_canDoIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ActivityAttemptCanDo map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ActivityAttemptCanDo(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      attemptId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempt_id'],
      )!,
      canDoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}can_do_id'],
      )!,
    );
  }

  @override
  $ActivityAttemptCanDosTable createAlias(String alias) {
    return $ActivityAttemptCanDosTable(attachedDatabase, alias);
  }
}

class ActivityAttemptCanDo extends DataClass
    implements Insertable<ActivityAttemptCanDo> {
  final int id;
  final int attemptId;
  final String canDoId;
  const ActivityAttemptCanDo({
    required this.id,
    required this.attemptId,
    required this.canDoId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['attempt_id'] = Variable<int>(attemptId);
    map['can_do_id'] = Variable<String>(canDoId);
    return map;
  }

  ActivityAttemptCanDosCompanion toCompanion(bool nullToAbsent) {
    return ActivityAttemptCanDosCompanion(
      id: Value(id),
      attemptId: Value(attemptId),
      canDoId: Value(canDoId),
    );
  }

  factory ActivityAttemptCanDo.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ActivityAttemptCanDo(
      id: serializer.fromJson<int>(json['id']),
      attemptId: serializer.fromJson<int>(json['attemptId']),
      canDoId: serializer.fromJson<String>(json['canDoId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'attemptId': serializer.toJson<int>(attemptId),
      'canDoId': serializer.toJson<String>(canDoId),
    };
  }

  ActivityAttemptCanDo copyWith({int? id, int? attemptId, String? canDoId}) =>
      ActivityAttemptCanDo(
        id: id ?? this.id,
        attemptId: attemptId ?? this.attemptId,
        canDoId: canDoId ?? this.canDoId,
      );
  ActivityAttemptCanDo copyWithCompanion(ActivityAttemptCanDosCompanion data) {
    return ActivityAttemptCanDo(
      id: data.id.present ? data.id.value : this.id,
      attemptId: data.attemptId.present ? data.attemptId.value : this.attemptId,
      canDoId: data.canDoId.present ? data.canDoId.value : this.canDoId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ActivityAttemptCanDo(')
          ..write('id: $id, ')
          ..write('attemptId: $attemptId, ')
          ..write('canDoId: $canDoId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, attemptId, canDoId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ActivityAttemptCanDo &&
          other.id == this.id &&
          other.attemptId == this.attemptId &&
          other.canDoId == this.canDoId);
}

class ActivityAttemptCanDosCompanion
    extends UpdateCompanion<ActivityAttemptCanDo> {
  final Value<int> id;
  final Value<int> attemptId;
  final Value<String> canDoId;
  const ActivityAttemptCanDosCompanion({
    this.id = const Value.absent(),
    this.attemptId = const Value.absent(),
    this.canDoId = const Value.absent(),
  });
  ActivityAttemptCanDosCompanion.insert({
    this.id = const Value.absent(),
    required int attemptId,
    required String canDoId,
  }) : attemptId = Value(attemptId),
       canDoId = Value(canDoId);
  static Insertable<ActivityAttemptCanDo> custom({
    Expression<int>? id,
    Expression<int>? attemptId,
    Expression<String>? canDoId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (attemptId != null) 'attempt_id': attemptId,
      if (canDoId != null) 'can_do_id': canDoId,
    });
  }

  ActivityAttemptCanDosCompanion copyWith({
    Value<int>? id,
    Value<int>? attemptId,
    Value<String>? canDoId,
  }) {
    return ActivityAttemptCanDosCompanion(
      id: id ?? this.id,
      attemptId: attemptId ?? this.attemptId,
      canDoId: canDoId ?? this.canDoId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (attemptId.present) {
      map['attempt_id'] = Variable<int>(attemptId.value);
    }
    if (canDoId.present) {
      map['can_do_id'] = Variable<String>(canDoId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ActivityAttemptCanDosCompanion(')
          ..write('id: $id, ')
          ..write('attemptId: $attemptId, ')
          ..write('canDoId: $canDoId')
          ..write(')'))
        .toString();
  }
}

class $PlacementAttemptsTable extends PlacementAttempts
    with TableInfo<$PlacementAttemptsTable, PlacementAttempt> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlacementAttemptsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _learnerIdMeta = const VerificationMeta(
    'learnerId',
  );
  @override
  late final GeneratedColumn<int> learnerId = GeneratedColumn<int>(
    'learner_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES learners (id)',
    ),
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stageReachedMeta = const VerificationMeta(
    'stageReached',
  );
  @override
  late final GeneratedColumn<int> stageReached = GeneratedColumn<int>(
    'stage_reached',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _outcomeMeta = const VerificationMeta(
    'outcome',
  );
  @override
  late final GeneratedColumn<String> outcome = GeneratedColumn<String>(
    'outcome',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recommendedUnitIdMeta = const VerificationMeta(
    'recommendedUnitId',
  );
  @override
  late final GeneratedColumn<String> recommendedUnitId =
      GeneratedColumn<String>(
        'recommended_unit_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _confidenceSelfReportsMeta =
      const VerificationMeta('confidenceSelfReports');
  @override
  late final GeneratedColumn<String> confidenceSelfReports =
      GeneratedColumn<String>(
        'confidence_self_reports',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _itemSamplingSeedMeta = const VerificationMeta(
    'itemSamplingSeed',
  );
  @override
  late final GeneratedColumn<String> itemSamplingSeed = GeneratedColumn<String>(
    'item_sampling_seed',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    uuid,
    learnerId,
    startedAt,
    completedAt,
    stageReached,
    outcome,
    recommendedUnitId,
    confidenceSelfReports,
    itemSamplingSeed,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'placement_attempts';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlacementAttempt> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('learner_id')) {
      context.handle(
        _learnerIdMeta,
        learnerId.isAcceptableOrUnknown(data['learner_id']!, _learnerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_learnerIdMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('stage_reached')) {
      context.handle(
        _stageReachedMeta,
        stageReached.isAcceptableOrUnknown(
          data['stage_reached']!,
          _stageReachedMeta,
        ),
      );
    }
    if (data.containsKey('outcome')) {
      context.handle(
        _outcomeMeta,
        outcome.isAcceptableOrUnknown(data['outcome']!, _outcomeMeta),
      );
    }
    if (data.containsKey('recommended_unit_id')) {
      context.handle(
        _recommendedUnitIdMeta,
        recommendedUnitId.isAcceptableOrUnknown(
          data['recommended_unit_id']!,
          _recommendedUnitIdMeta,
        ),
      );
    }
    if (data.containsKey('confidence_self_reports')) {
      context.handle(
        _confidenceSelfReportsMeta,
        confidenceSelfReports.isAcceptableOrUnknown(
          data['confidence_self_reports']!,
          _confidenceSelfReportsMeta,
        ),
      );
    }
    if (data.containsKey('item_sampling_seed')) {
      context.handle(
        _itemSamplingSeedMeta,
        itemSamplingSeed.isAcceptableOrUnknown(
          data['item_sampling_seed']!,
          _itemSamplingSeedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlacementAttempt map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlacementAttempt(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      learnerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}learner_id'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
      stageReached: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stage_reached'],
      )!,
      outcome: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}outcome'],
      ),
      recommendedUnitId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recommended_unit_id'],
      ),
      confidenceSelfReports: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}confidence_self_reports'],
      ),
      itemSamplingSeed: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_sampling_seed'],
      ),
    );
  }

  @override
  $PlacementAttemptsTable createAlias(String alias) {
    return $PlacementAttemptsTable(attachedDatabase, alias);
  }
}

class PlacementAttempt extends DataClass
    implements Insertable<PlacementAttempt> {
  final int id;
  final String uuid;
  final int learnerId;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int stageReached;
  final String? outcome;
  final String? recommendedUnitId;
  final String? confidenceSelfReports;
  final String? itemSamplingSeed;
  const PlacementAttempt({
    required this.id,
    required this.uuid,
    required this.learnerId,
    required this.startedAt,
    this.completedAt,
    required this.stageReached,
    this.outcome,
    this.recommendedUnitId,
    this.confidenceSelfReports,
    this.itemSamplingSeed,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    map['learner_id'] = Variable<int>(learnerId);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    map['stage_reached'] = Variable<int>(stageReached);
    if (!nullToAbsent || outcome != null) {
      map['outcome'] = Variable<String>(outcome);
    }
    if (!nullToAbsent || recommendedUnitId != null) {
      map['recommended_unit_id'] = Variable<String>(recommendedUnitId);
    }
    if (!nullToAbsent || confidenceSelfReports != null) {
      map['confidence_self_reports'] = Variable<String>(confidenceSelfReports);
    }
    if (!nullToAbsent || itemSamplingSeed != null) {
      map['item_sampling_seed'] = Variable<String>(itemSamplingSeed);
    }
    return map;
  }

  PlacementAttemptsCompanion toCompanion(bool nullToAbsent) {
    return PlacementAttemptsCompanion(
      id: Value(id),
      uuid: Value(uuid),
      learnerId: Value(learnerId),
      startedAt: Value(startedAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      stageReached: Value(stageReached),
      outcome: outcome == null && nullToAbsent
          ? const Value.absent()
          : Value(outcome),
      recommendedUnitId: recommendedUnitId == null && nullToAbsent
          ? const Value.absent()
          : Value(recommendedUnitId),
      confidenceSelfReports: confidenceSelfReports == null && nullToAbsent
          ? const Value.absent()
          : Value(confidenceSelfReports),
      itemSamplingSeed: itemSamplingSeed == null && nullToAbsent
          ? const Value.absent()
          : Value(itemSamplingSeed),
    );
  }

  factory PlacementAttempt.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlacementAttempt(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      learnerId: serializer.fromJson<int>(json['learnerId']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      stageReached: serializer.fromJson<int>(json['stageReached']),
      outcome: serializer.fromJson<String?>(json['outcome']),
      recommendedUnitId: serializer.fromJson<String?>(
        json['recommendedUnitId'],
      ),
      confidenceSelfReports: serializer.fromJson<String?>(
        json['confidenceSelfReports'],
      ),
      itemSamplingSeed: serializer.fromJson<String?>(json['itemSamplingSeed']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'learnerId': serializer.toJson<int>(learnerId),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'stageReached': serializer.toJson<int>(stageReached),
      'outcome': serializer.toJson<String?>(outcome),
      'recommendedUnitId': serializer.toJson<String?>(recommendedUnitId),
      'confidenceSelfReports': serializer.toJson<String?>(
        confidenceSelfReports,
      ),
      'itemSamplingSeed': serializer.toJson<String?>(itemSamplingSeed),
    };
  }

  PlacementAttempt copyWith({
    int? id,
    String? uuid,
    int? learnerId,
    DateTime? startedAt,
    Value<DateTime?> completedAt = const Value.absent(),
    int? stageReached,
    Value<String?> outcome = const Value.absent(),
    Value<String?> recommendedUnitId = const Value.absent(),
    Value<String?> confidenceSelfReports = const Value.absent(),
    Value<String?> itemSamplingSeed = const Value.absent(),
  }) => PlacementAttempt(
    id: id ?? this.id,
    uuid: uuid ?? this.uuid,
    learnerId: learnerId ?? this.learnerId,
    startedAt: startedAt ?? this.startedAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    stageReached: stageReached ?? this.stageReached,
    outcome: outcome.present ? outcome.value : this.outcome,
    recommendedUnitId: recommendedUnitId.present
        ? recommendedUnitId.value
        : this.recommendedUnitId,
    confidenceSelfReports: confidenceSelfReports.present
        ? confidenceSelfReports.value
        : this.confidenceSelfReports,
    itemSamplingSeed: itemSamplingSeed.present
        ? itemSamplingSeed.value
        : this.itemSamplingSeed,
  );
  PlacementAttempt copyWithCompanion(PlacementAttemptsCompanion data) {
    return PlacementAttempt(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      learnerId: data.learnerId.present ? data.learnerId.value : this.learnerId,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      stageReached: data.stageReached.present
          ? data.stageReached.value
          : this.stageReached,
      outcome: data.outcome.present ? data.outcome.value : this.outcome,
      recommendedUnitId: data.recommendedUnitId.present
          ? data.recommendedUnitId.value
          : this.recommendedUnitId,
      confidenceSelfReports: data.confidenceSelfReports.present
          ? data.confidenceSelfReports.value
          : this.confidenceSelfReports,
      itemSamplingSeed: data.itemSamplingSeed.present
          ? data.itemSamplingSeed.value
          : this.itemSamplingSeed,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlacementAttempt(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('learnerId: $learnerId, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('stageReached: $stageReached, ')
          ..write('outcome: $outcome, ')
          ..write('recommendedUnitId: $recommendedUnitId, ')
          ..write('confidenceSelfReports: $confidenceSelfReports, ')
          ..write('itemSamplingSeed: $itemSamplingSeed')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    uuid,
    learnerId,
    startedAt,
    completedAt,
    stageReached,
    outcome,
    recommendedUnitId,
    confidenceSelfReports,
    itemSamplingSeed,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlacementAttempt &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.learnerId == this.learnerId &&
          other.startedAt == this.startedAt &&
          other.completedAt == this.completedAt &&
          other.stageReached == this.stageReached &&
          other.outcome == this.outcome &&
          other.recommendedUnitId == this.recommendedUnitId &&
          other.confidenceSelfReports == this.confidenceSelfReports &&
          other.itemSamplingSeed == this.itemSamplingSeed);
}

class PlacementAttemptsCompanion extends UpdateCompanion<PlacementAttempt> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<int> learnerId;
  final Value<DateTime> startedAt;
  final Value<DateTime?> completedAt;
  final Value<int> stageReached;
  final Value<String?> outcome;
  final Value<String?> recommendedUnitId;
  final Value<String?> confidenceSelfReports;
  final Value<String?> itemSamplingSeed;
  const PlacementAttemptsCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.learnerId = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.stageReached = const Value.absent(),
    this.outcome = const Value.absent(),
    this.recommendedUnitId = const Value.absent(),
    this.confidenceSelfReports = const Value.absent(),
    this.itemSamplingSeed = const Value.absent(),
  });
  PlacementAttemptsCompanion.insert({
    this.id = const Value.absent(),
    required String uuid,
    required int learnerId,
    required DateTime startedAt,
    this.completedAt = const Value.absent(),
    this.stageReached = const Value.absent(),
    this.outcome = const Value.absent(),
    this.recommendedUnitId = const Value.absent(),
    this.confidenceSelfReports = const Value.absent(),
    this.itemSamplingSeed = const Value.absent(),
  }) : uuid = Value(uuid),
       learnerId = Value(learnerId),
       startedAt = Value(startedAt);
  static Insertable<PlacementAttempt> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<int>? learnerId,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? completedAt,
    Expression<int>? stageReached,
    Expression<String>? outcome,
    Expression<String>? recommendedUnitId,
    Expression<String>? confidenceSelfReports,
    Expression<String>? itemSamplingSeed,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (learnerId != null) 'learner_id': learnerId,
      if (startedAt != null) 'started_at': startedAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (stageReached != null) 'stage_reached': stageReached,
      if (outcome != null) 'outcome': outcome,
      if (recommendedUnitId != null) 'recommended_unit_id': recommendedUnitId,
      if (confidenceSelfReports != null)
        'confidence_self_reports': confidenceSelfReports,
      if (itemSamplingSeed != null) 'item_sampling_seed': itemSamplingSeed,
    });
  }

  PlacementAttemptsCompanion copyWith({
    Value<int>? id,
    Value<String>? uuid,
    Value<int>? learnerId,
    Value<DateTime>? startedAt,
    Value<DateTime?>? completedAt,
    Value<int>? stageReached,
    Value<String?>? outcome,
    Value<String?>? recommendedUnitId,
    Value<String?>? confidenceSelfReports,
    Value<String?>? itemSamplingSeed,
  }) {
    return PlacementAttemptsCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      learnerId: learnerId ?? this.learnerId,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      stageReached: stageReached ?? this.stageReached,
      outcome: outcome ?? this.outcome,
      recommendedUnitId: recommendedUnitId ?? this.recommendedUnitId,
      confidenceSelfReports:
          confidenceSelfReports ?? this.confidenceSelfReports,
      itemSamplingSeed: itemSamplingSeed ?? this.itemSamplingSeed,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (learnerId.present) {
      map['learner_id'] = Variable<int>(learnerId.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (stageReached.present) {
      map['stage_reached'] = Variable<int>(stageReached.value);
    }
    if (outcome.present) {
      map['outcome'] = Variable<String>(outcome.value);
    }
    if (recommendedUnitId.present) {
      map['recommended_unit_id'] = Variable<String>(recommendedUnitId.value);
    }
    if (confidenceSelfReports.present) {
      map['confidence_self_reports'] = Variable<String>(
        confidenceSelfReports.value,
      );
    }
    if (itemSamplingSeed.present) {
      map['item_sampling_seed'] = Variable<String>(itemSamplingSeed.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlacementAttemptsCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('learnerId: $learnerId, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('stageReached: $stageReached, ')
          ..write('outcome: $outcome, ')
          ..write('recommendedUnitId: $recommendedUnitId, ')
          ..write('confidenceSelfReports: $confidenceSelfReports, ')
          ..write('itemSamplingSeed: $itemSamplingSeed')
          ..write(')'))
        .toString();
  }
}

class $FinalMissionAttemptsTable extends FinalMissionAttempts
    with TableInfo<$FinalMissionAttemptsTable, FinalMissionAttempt> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FinalMissionAttemptsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _learnerIdMeta = const VerificationMeta(
    'learnerId',
  );
  @override
  late final GeneratedColumn<int> learnerId = GeneratedColumn<int>(
    'learner_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES learners (id)',
    ),
  );
  static const VerificationMeta _courseIdMeta = const VerificationMeta(
    'courseId',
  );
  @override
  late final GeneratedColumn<String> courseId = GeneratedColumn<String>(
    'course_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stagesCompletedMeta = const VerificationMeta(
    'stagesCompleted',
  );
  @override
  late final GeneratedColumn<String> stagesCompleted = GeneratedColumn<String>(
    'stages_completed',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _outcomeMeta = const VerificationMeta(
    'outcome',
  );
  @override
  late final GeneratedColumn<String> outcome = GeneratedColumn<String>(
    'outcome',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    uuid,
    learnerId,
    courseId,
    startedAt,
    completedAt,
    stagesCompleted,
    outcome,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'final_mission_attempts';
  @override
  VerificationContext validateIntegrity(
    Insertable<FinalMissionAttempt> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('learner_id')) {
      context.handle(
        _learnerIdMeta,
        learnerId.isAcceptableOrUnknown(data['learner_id']!, _learnerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_learnerIdMeta);
    }
    if (data.containsKey('course_id')) {
      context.handle(
        _courseIdMeta,
        courseId.isAcceptableOrUnknown(data['course_id']!, _courseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_courseIdMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('stages_completed')) {
      context.handle(
        _stagesCompletedMeta,
        stagesCompleted.isAcceptableOrUnknown(
          data['stages_completed']!,
          _stagesCompletedMeta,
        ),
      );
    }
    if (data.containsKey('outcome')) {
      context.handle(
        _outcomeMeta,
        outcome.isAcceptableOrUnknown(data['outcome']!, _outcomeMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FinalMissionAttempt map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FinalMissionAttempt(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      learnerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}learner_id'],
      )!,
      courseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}course_id'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
      stagesCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stages_completed'],
      ),
      outcome: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}outcome'],
      ),
    );
  }

  @override
  $FinalMissionAttemptsTable createAlias(String alias) {
    return $FinalMissionAttemptsTable(attachedDatabase, alias);
  }
}

class FinalMissionAttempt extends DataClass
    implements Insertable<FinalMissionAttempt> {
  final int id;
  final String uuid;
  final int learnerId;
  final String courseId;
  final DateTime startedAt;
  final DateTime? completedAt;
  final String? stagesCompleted;
  final String? outcome;
  const FinalMissionAttempt({
    required this.id,
    required this.uuid,
    required this.learnerId,
    required this.courseId,
    required this.startedAt,
    this.completedAt,
    this.stagesCompleted,
    this.outcome,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    map['learner_id'] = Variable<int>(learnerId);
    map['course_id'] = Variable<String>(courseId);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    if (!nullToAbsent || stagesCompleted != null) {
      map['stages_completed'] = Variable<String>(stagesCompleted);
    }
    if (!nullToAbsent || outcome != null) {
      map['outcome'] = Variable<String>(outcome);
    }
    return map;
  }

  FinalMissionAttemptsCompanion toCompanion(bool nullToAbsent) {
    return FinalMissionAttemptsCompanion(
      id: Value(id),
      uuid: Value(uuid),
      learnerId: Value(learnerId),
      courseId: Value(courseId),
      startedAt: Value(startedAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      stagesCompleted: stagesCompleted == null && nullToAbsent
          ? const Value.absent()
          : Value(stagesCompleted),
      outcome: outcome == null && nullToAbsent
          ? const Value.absent()
          : Value(outcome),
    );
  }

  factory FinalMissionAttempt.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FinalMissionAttempt(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      learnerId: serializer.fromJson<int>(json['learnerId']),
      courseId: serializer.fromJson<String>(json['courseId']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      stagesCompleted: serializer.fromJson<String?>(json['stagesCompleted']),
      outcome: serializer.fromJson<String?>(json['outcome']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'learnerId': serializer.toJson<int>(learnerId),
      'courseId': serializer.toJson<String>(courseId),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'stagesCompleted': serializer.toJson<String?>(stagesCompleted),
      'outcome': serializer.toJson<String?>(outcome),
    };
  }

  FinalMissionAttempt copyWith({
    int? id,
    String? uuid,
    int? learnerId,
    String? courseId,
    DateTime? startedAt,
    Value<DateTime?> completedAt = const Value.absent(),
    Value<String?> stagesCompleted = const Value.absent(),
    Value<String?> outcome = const Value.absent(),
  }) => FinalMissionAttempt(
    id: id ?? this.id,
    uuid: uuid ?? this.uuid,
    learnerId: learnerId ?? this.learnerId,
    courseId: courseId ?? this.courseId,
    startedAt: startedAt ?? this.startedAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    stagesCompleted: stagesCompleted.present
        ? stagesCompleted.value
        : this.stagesCompleted,
    outcome: outcome.present ? outcome.value : this.outcome,
  );
  FinalMissionAttempt copyWithCompanion(FinalMissionAttemptsCompanion data) {
    return FinalMissionAttempt(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      learnerId: data.learnerId.present ? data.learnerId.value : this.learnerId,
      courseId: data.courseId.present ? data.courseId.value : this.courseId,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      stagesCompleted: data.stagesCompleted.present
          ? data.stagesCompleted.value
          : this.stagesCompleted,
      outcome: data.outcome.present ? data.outcome.value : this.outcome,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FinalMissionAttempt(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('learnerId: $learnerId, ')
          ..write('courseId: $courseId, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('stagesCompleted: $stagesCompleted, ')
          ..write('outcome: $outcome')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    uuid,
    learnerId,
    courseId,
    startedAt,
    completedAt,
    stagesCompleted,
    outcome,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FinalMissionAttempt &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.learnerId == this.learnerId &&
          other.courseId == this.courseId &&
          other.startedAt == this.startedAt &&
          other.completedAt == this.completedAt &&
          other.stagesCompleted == this.stagesCompleted &&
          other.outcome == this.outcome);
}

class FinalMissionAttemptsCompanion
    extends UpdateCompanion<FinalMissionAttempt> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<int> learnerId;
  final Value<String> courseId;
  final Value<DateTime> startedAt;
  final Value<DateTime?> completedAt;
  final Value<String?> stagesCompleted;
  final Value<String?> outcome;
  const FinalMissionAttemptsCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.learnerId = const Value.absent(),
    this.courseId = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.stagesCompleted = const Value.absent(),
    this.outcome = const Value.absent(),
  });
  FinalMissionAttemptsCompanion.insert({
    this.id = const Value.absent(),
    required String uuid,
    required int learnerId,
    required String courseId,
    required DateTime startedAt,
    this.completedAt = const Value.absent(),
    this.stagesCompleted = const Value.absent(),
    this.outcome = const Value.absent(),
  }) : uuid = Value(uuid),
       learnerId = Value(learnerId),
       courseId = Value(courseId),
       startedAt = Value(startedAt);
  static Insertable<FinalMissionAttempt> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<int>? learnerId,
    Expression<String>? courseId,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? completedAt,
    Expression<String>? stagesCompleted,
    Expression<String>? outcome,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (learnerId != null) 'learner_id': learnerId,
      if (courseId != null) 'course_id': courseId,
      if (startedAt != null) 'started_at': startedAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (stagesCompleted != null) 'stages_completed': stagesCompleted,
      if (outcome != null) 'outcome': outcome,
    });
  }

  FinalMissionAttemptsCompanion copyWith({
    Value<int>? id,
    Value<String>? uuid,
    Value<int>? learnerId,
    Value<String>? courseId,
    Value<DateTime>? startedAt,
    Value<DateTime?>? completedAt,
    Value<String?>? stagesCompleted,
    Value<String?>? outcome,
  }) {
    return FinalMissionAttemptsCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      learnerId: learnerId ?? this.learnerId,
      courseId: courseId ?? this.courseId,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      stagesCompleted: stagesCompleted ?? this.stagesCompleted,
      outcome: outcome ?? this.outcome,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (learnerId.present) {
      map['learner_id'] = Variable<int>(learnerId.value);
    }
    if (courseId.present) {
      map['course_id'] = Variable<String>(courseId.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (stagesCompleted.present) {
      map['stages_completed'] = Variable<String>(stagesCompleted.value);
    }
    if (outcome.present) {
      map['outcome'] = Variable<String>(outcome.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FinalMissionAttemptsCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('learnerId: $learnerId, ')
          ..write('courseId: $courseId, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('stagesCompleted: $stagesCompleted, ')
          ..write('outcome: $outcome')
          ..write(')'))
        .toString();
  }
}

class $FinalAssessmentAttemptsTable extends FinalAssessmentAttempts
    with TableInfo<$FinalAssessmentAttemptsTable, FinalAssessmentAttempt> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FinalAssessmentAttemptsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _learnerIdMeta = const VerificationMeta(
    'learnerId',
  );
  @override
  late final GeneratedColumn<int> learnerId = GeneratedColumn<int>(
    'learner_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES learners (id)',
    ),
  );
  static const VerificationMeta _courseIdMeta = const VerificationMeta(
    'courseId',
  );
  @override
  late final GeneratedColumn<String> courseId = GeneratedColumn<String>(
    'course_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sectionResultsMeta = const VerificationMeta(
    'sectionResults',
  );
  @override
  late final GeneratedColumn<String> sectionResults = GeneratedColumn<String>(
    'section_results',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _outcomeSummaryMeta = const VerificationMeta(
    'outcomeSummary',
  );
  @override
  late final GeneratedColumn<String> outcomeSummary = GeneratedColumn<String>(
    'outcome_summary',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    uuid,
    learnerId,
    courseId,
    startedAt,
    completedAt,
    sectionResults,
    outcomeSummary,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'final_assessment_attempts';
  @override
  VerificationContext validateIntegrity(
    Insertable<FinalAssessmentAttempt> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('learner_id')) {
      context.handle(
        _learnerIdMeta,
        learnerId.isAcceptableOrUnknown(data['learner_id']!, _learnerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_learnerIdMeta);
    }
    if (data.containsKey('course_id')) {
      context.handle(
        _courseIdMeta,
        courseId.isAcceptableOrUnknown(data['course_id']!, _courseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_courseIdMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('section_results')) {
      context.handle(
        _sectionResultsMeta,
        sectionResults.isAcceptableOrUnknown(
          data['section_results']!,
          _sectionResultsMeta,
        ),
      );
    }
    if (data.containsKey('outcome_summary')) {
      context.handle(
        _outcomeSummaryMeta,
        outcomeSummary.isAcceptableOrUnknown(
          data['outcome_summary']!,
          _outcomeSummaryMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FinalAssessmentAttempt map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FinalAssessmentAttempt(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      learnerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}learner_id'],
      )!,
      courseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}course_id'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
      sectionResults: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}section_results'],
      ),
      outcomeSummary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}outcome_summary'],
      ),
    );
  }

  @override
  $FinalAssessmentAttemptsTable createAlias(String alias) {
    return $FinalAssessmentAttemptsTable(attachedDatabase, alias);
  }
}

class FinalAssessmentAttempt extends DataClass
    implements Insertable<FinalAssessmentAttempt> {
  final int id;
  final String uuid;
  final int learnerId;
  final String courseId;
  final DateTime startedAt;
  final DateTime? completedAt;
  final String? sectionResults;
  final String? outcomeSummary;
  const FinalAssessmentAttempt({
    required this.id,
    required this.uuid,
    required this.learnerId,
    required this.courseId,
    required this.startedAt,
    this.completedAt,
    this.sectionResults,
    this.outcomeSummary,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    map['learner_id'] = Variable<int>(learnerId);
    map['course_id'] = Variable<String>(courseId);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    if (!nullToAbsent || sectionResults != null) {
      map['section_results'] = Variable<String>(sectionResults);
    }
    if (!nullToAbsent || outcomeSummary != null) {
      map['outcome_summary'] = Variable<String>(outcomeSummary);
    }
    return map;
  }

  FinalAssessmentAttemptsCompanion toCompanion(bool nullToAbsent) {
    return FinalAssessmentAttemptsCompanion(
      id: Value(id),
      uuid: Value(uuid),
      learnerId: Value(learnerId),
      courseId: Value(courseId),
      startedAt: Value(startedAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      sectionResults: sectionResults == null && nullToAbsent
          ? const Value.absent()
          : Value(sectionResults),
      outcomeSummary: outcomeSummary == null && nullToAbsent
          ? const Value.absent()
          : Value(outcomeSummary),
    );
  }

  factory FinalAssessmentAttempt.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FinalAssessmentAttempt(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      learnerId: serializer.fromJson<int>(json['learnerId']),
      courseId: serializer.fromJson<String>(json['courseId']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      sectionResults: serializer.fromJson<String?>(json['sectionResults']),
      outcomeSummary: serializer.fromJson<String?>(json['outcomeSummary']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'learnerId': serializer.toJson<int>(learnerId),
      'courseId': serializer.toJson<String>(courseId),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'sectionResults': serializer.toJson<String?>(sectionResults),
      'outcomeSummary': serializer.toJson<String?>(outcomeSummary),
    };
  }

  FinalAssessmentAttempt copyWith({
    int? id,
    String? uuid,
    int? learnerId,
    String? courseId,
    DateTime? startedAt,
    Value<DateTime?> completedAt = const Value.absent(),
    Value<String?> sectionResults = const Value.absent(),
    Value<String?> outcomeSummary = const Value.absent(),
  }) => FinalAssessmentAttempt(
    id: id ?? this.id,
    uuid: uuid ?? this.uuid,
    learnerId: learnerId ?? this.learnerId,
    courseId: courseId ?? this.courseId,
    startedAt: startedAt ?? this.startedAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    sectionResults: sectionResults.present
        ? sectionResults.value
        : this.sectionResults,
    outcomeSummary: outcomeSummary.present
        ? outcomeSummary.value
        : this.outcomeSummary,
  );
  FinalAssessmentAttempt copyWithCompanion(
    FinalAssessmentAttemptsCompanion data,
  ) {
    return FinalAssessmentAttempt(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      learnerId: data.learnerId.present ? data.learnerId.value : this.learnerId,
      courseId: data.courseId.present ? data.courseId.value : this.courseId,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      sectionResults: data.sectionResults.present
          ? data.sectionResults.value
          : this.sectionResults,
      outcomeSummary: data.outcomeSummary.present
          ? data.outcomeSummary.value
          : this.outcomeSummary,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FinalAssessmentAttempt(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('learnerId: $learnerId, ')
          ..write('courseId: $courseId, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('sectionResults: $sectionResults, ')
          ..write('outcomeSummary: $outcomeSummary')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    uuid,
    learnerId,
    courseId,
    startedAt,
    completedAt,
    sectionResults,
    outcomeSummary,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FinalAssessmentAttempt &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.learnerId == this.learnerId &&
          other.courseId == this.courseId &&
          other.startedAt == this.startedAt &&
          other.completedAt == this.completedAt &&
          other.sectionResults == this.sectionResults &&
          other.outcomeSummary == this.outcomeSummary);
}

class FinalAssessmentAttemptsCompanion
    extends UpdateCompanion<FinalAssessmentAttempt> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<int> learnerId;
  final Value<String> courseId;
  final Value<DateTime> startedAt;
  final Value<DateTime?> completedAt;
  final Value<String?> sectionResults;
  final Value<String?> outcomeSummary;
  const FinalAssessmentAttemptsCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.learnerId = const Value.absent(),
    this.courseId = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.sectionResults = const Value.absent(),
    this.outcomeSummary = const Value.absent(),
  });
  FinalAssessmentAttemptsCompanion.insert({
    this.id = const Value.absent(),
    required String uuid,
    required int learnerId,
    required String courseId,
    required DateTime startedAt,
    this.completedAt = const Value.absent(),
    this.sectionResults = const Value.absent(),
    this.outcomeSummary = const Value.absent(),
  }) : uuid = Value(uuid),
       learnerId = Value(learnerId),
       courseId = Value(courseId),
       startedAt = Value(startedAt);
  static Insertable<FinalAssessmentAttempt> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<int>? learnerId,
    Expression<String>? courseId,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? completedAt,
    Expression<String>? sectionResults,
    Expression<String>? outcomeSummary,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (learnerId != null) 'learner_id': learnerId,
      if (courseId != null) 'course_id': courseId,
      if (startedAt != null) 'started_at': startedAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (sectionResults != null) 'section_results': sectionResults,
      if (outcomeSummary != null) 'outcome_summary': outcomeSummary,
    });
  }

  FinalAssessmentAttemptsCompanion copyWith({
    Value<int>? id,
    Value<String>? uuid,
    Value<int>? learnerId,
    Value<String>? courseId,
    Value<DateTime>? startedAt,
    Value<DateTime?>? completedAt,
    Value<String?>? sectionResults,
    Value<String?>? outcomeSummary,
  }) {
    return FinalAssessmentAttemptsCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      learnerId: learnerId ?? this.learnerId,
      courseId: courseId ?? this.courseId,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      sectionResults: sectionResults ?? this.sectionResults,
      outcomeSummary: outcomeSummary ?? this.outcomeSummary,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (learnerId.present) {
      map['learner_id'] = Variable<int>(learnerId.value);
    }
    if (courseId.present) {
      map['course_id'] = Variable<String>(courseId.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (sectionResults.present) {
      map['section_results'] = Variable<String>(sectionResults.value);
    }
    if (outcomeSummary.present) {
      map['outcome_summary'] = Variable<String>(outcomeSummary.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FinalAssessmentAttemptsCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('learnerId: $learnerId, ')
          ..write('courseId: $courseId, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('sectionResults: $sectionResults, ')
          ..write('outcomeSummary: $outcomeSummary')
          ..write(')'))
        .toString();
  }
}

class $VocabularyReviewStateTable extends VocabularyReviewState
    with TableInfo<$VocabularyReviewStateTable, VocabularyReviewStateData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VocabularyReviewStateTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _learnerIdMeta = const VerificationMeta(
    'learnerId',
  );
  @override
  late final GeneratedColumn<int> learnerId = GeneratedColumn<int>(
    'learner_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES learners (id)',
    ),
  );
  static const VerificationMeta _lexiconIdMeta = const VerificationMeta(
    'lexiconId',
  );
  @override
  late final GeneratedColumn<String> lexiconId = GeneratedColumn<String>(
    'lexicon_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _chunkIdMeta = const VerificationMeta(
    'chunkId',
  );
  @override
  late final GeneratedColumn<String> chunkId = GeneratedColumn<String>(
    'chunk_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isFavoriteMeta = const VerificationMeta(
    'isFavorite',
  );
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
    'is_favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_favorite" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _confidenceMarkerMeta = const VerificationMeta(
    'confidenceMarker',
  );
  @override
  late final GeneratedColumn<String> confidenceMarker = GeneratedColumn<String>(
    'confidence_marker',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _easeFactorMeta = const VerificationMeta(
    'easeFactor',
  );
  @override
  late final GeneratedColumn<double> easeFactor = GeneratedColumn<double>(
    'ease_factor',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(2.5),
  );
  static const VerificationMeta _intervalDaysMeta = const VerificationMeta(
    'intervalDays',
  );
  @override
  late final GeneratedColumn<int> intervalDays = GeneratedColumn<int>(
    'interval_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _repetitionsMeta = const VerificationMeta(
    'repetitions',
  );
  @override
  late final GeneratedColumn<int> repetitions = GeneratedColumn<int>(
    'repetitions',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _dueAtMeta = const VerificationMeta('dueAt');
  @override
  late final GeneratedColumn<DateTime> dueAt = GeneratedColumn<DateTime>(
    'due_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastReviewedAtMeta = const VerificationMeta(
    'lastReviewedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastReviewedAt =
      GeneratedColumn<DateTime>(
        'last_reviewed_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    uuid,
    learnerId,
    lexiconId,
    chunkId,
    isFavorite,
    confidenceMarker,
    easeFactor,
    intervalDays,
    repetitions,
    dueAt,
    lastReviewedAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vocabulary_review_state';
  @override
  VerificationContext validateIntegrity(
    Insertable<VocabularyReviewStateData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('learner_id')) {
      context.handle(
        _learnerIdMeta,
        learnerId.isAcceptableOrUnknown(data['learner_id']!, _learnerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_learnerIdMeta);
    }
    if (data.containsKey('lexicon_id')) {
      context.handle(
        _lexiconIdMeta,
        lexiconId.isAcceptableOrUnknown(data['lexicon_id']!, _lexiconIdMeta),
      );
    }
    if (data.containsKey('chunk_id')) {
      context.handle(
        _chunkIdMeta,
        chunkId.isAcceptableOrUnknown(data['chunk_id']!, _chunkIdMeta),
      );
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
        _isFavoriteMeta,
        isFavorite.isAcceptableOrUnknown(data['is_favorite']!, _isFavoriteMeta),
      );
    }
    if (data.containsKey('confidence_marker')) {
      context.handle(
        _confidenceMarkerMeta,
        confidenceMarker.isAcceptableOrUnknown(
          data['confidence_marker']!,
          _confidenceMarkerMeta,
        ),
      );
    }
    if (data.containsKey('ease_factor')) {
      context.handle(
        _easeFactorMeta,
        easeFactor.isAcceptableOrUnknown(data['ease_factor']!, _easeFactorMeta),
      );
    }
    if (data.containsKey('interval_days')) {
      context.handle(
        _intervalDaysMeta,
        intervalDays.isAcceptableOrUnknown(
          data['interval_days']!,
          _intervalDaysMeta,
        ),
      );
    }
    if (data.containsKey('repetitions')) {
      context.handle(
        _repetitionsMeta,
        repetitions.isAcceptableOrUnknown(
          data['repetitions']!,
          _repetitionsMeta,
        ),
      );
    }
    if (data.containsKey('due_at')) {
      context.handle(
        _dueAtMeta,
        dueAt.isAcceptableOrUnknown(data['due_at']!, _dueAtMeta),
      );
    }
    if (data.containsKey('last_reviewed_at')) {
      context.handle(
        _lastReviewedAtMeta,
        lastReviewedAt.isAcceptableOrUnknown(
          data['last_reviewed_at']!,
          _lastReviewedAtMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VocabularyReviewStateData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VocabularyReviewStateData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      learnerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}learner_id'],
      )!,
      lexiconId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lexicon_id'],
      ),
      chunkId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}chunk_id'],
      ),
      isFavorite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_favorite'],
      )!,
      confidenceMarker: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}confidence_marker'],
      ),
      easeFactor: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}ease_factor'],
      )!,
      intervalDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}interval_days'],
      )!,
      repetitions: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}repetitions'],
      )!,
      dueAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due_at'],
      ),
      lastReviewedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_reviewed_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $VocabularyReviewStateTable createAlias(String alias) {
    return $VocabularyReviewStateTable(attachedDatabase, alias);
  }
}

class VocabularyReviewStateData extends DataClass
    implements Insertable<VocabularyReviewStateData> {
  final int id;
  final String uuid;
  final int learnerId;
  final String? lexiconId;
  final String? chunkId;
  final bool isFavorite;
  final String? confidenceMarker;
  final double easeFactor;
  final int intervalDays;
  final int repetitions;
  final DateTime? dueAt;
  final DateTime? lastReviewedAt;
  final DateTime updatedAt;
  const VocabularyReviewStateData({
    required this.id,
    required this.uuid,
    required this.learnerId,
    this.lexiconId,
    this.chunkId,
    required this.isFavorite,
    this.confidenceMarker,
    required this.easeFactor,
    required this.intervalDays,
    required this.repetitions,
    this.dueAt,
    this.lastReviewedAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    map['learner_id'] = Variable<int>(learnerId);
    if (!nullToAbsent || lexiconId != null) {
      map['lexicon_id'] = Variable<String>(lexiconId);
    }
    if (!nullToAbsent || chunkId != null) {
      map['chunk_id'] = Variable<String>(chunkId);
    }
    map['is_favorite'] = Variable<bool>(isFavorite);
    if (!nullToAbsent || confidenceMarker != null) {
      map['confidence_marker'] = Variable<String>(confidenceMarker);
    }
    map['ease_factor'] = Variable<double>(easeFactor);
    map['interval_days'] = Variable<int>(intervalDays);
    map['repetitions'] = Variable<int>(repetitions);
    if (!nullToAbsent || dueAt != null) {
      map['due_at'] = Variable<DateTime>(dueAt);
    }
    if (!nullToAbsent || lastReviewedAt != null) {
      map['last_reviewed_at'] = Variable<DateTime>(lastReviewedAt);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  VocabularyReviewStateCompanion toCompanion(bool nullToAbsent) {
    return VocabularyReviewStateCompanion(
      id: Value(id),
      uuid: Value(uuid),
      learnerId: Value(learnerId),
      lexiconId: lexiconId == null && nullToAbsent
          ? const Value.absent()
          : Value(lexiconId),
      chunkId: chunkId == null && nullToAbsent
          ? const Value.absent()
          : Value(chunkId),
      isFavorite: Value(isFavorite),
      confidenceMarker: confidenceMarker == null && nullToAbsent
          ? const Value.absent()
          : Value(confidenceMarker),
      easeFactor: Value(easeFactor),
      intervalDays: Value(intervalDays),
      repetitions: Value(repetitions),
      dueAt: dueAt == null && nullToAbsent
          ? const Value.absent()
          : Value(dueAt),
      lastReviewedAt: lastReviewedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReviewedAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory VocabularyReviewStateData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VocabularyReviewStateData(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      learnerId: serializer.fromJson<int>(json['learnerId']),
      lexiconId: serializer.fromJson<String?>(json['lexiconId']),
      chunkId: serializer.fromJson<String?>(json['chunkId']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
      confidenceMarker: serializer.fromJson<String?>(json['confidenceMarker']),
      easeFactor: serializer.fromJson<double>(json['easeFactor']),
      intervalDays: serializer.fromJson<int>(json['intervalDays']),
      repetitions: serializer.fromJson<int>(json['repetitions']),
      dueAt: serializer.fromJson<DateTime?>(json['dueAt']),
      lastReviewedAt: serializer.fromJson<DateTime?>(json['lastReviewedAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'learnerId': serializer.toJson<int>(learnerId),
      'lexiconId': serializer.toJson<String?>(lexiconId),
      'chunkId': serializer.toJson<String?>(chunkId),
      'isFavorite': serializer.toJson<bool>(isFavorite),
      'confidenceMarker': serializer.toJson<String?>(confidenceMarker),
      'easeFactor': serializer.toJson<double>(easeFactor),
      'intervalDays': serializer.toJson<int>(intervalDays),
      'repetitions': serializer.toJson<int>(repetitions),
      'dueAt': serializer.toJson<DateTime?>(dueAt),
      'lastReviewedAt': serializer.toJson<DateTime?>(lastReviewedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  VocabularyReviewStateData copyWith({
    int? id,
    String? uuid,
    int? learnerId,
    Value<String?> lexiconId = const Value.absent(),
    Value<String?> chunkId = const Value.absent(),
    bool? isFavorite,
    Value<String?> confidenceMarker = const Value.absent(),
    double? easeFactor,
    int? intervalDays,
    int? repetitions,
    Value<DateTime?> dueAt = const Value.absent(),
    Value<DateTime?> lastReviewedAt = const Value.absent(),
    DateTime? updatedAt,
  }) => VocabularyReviewStateData(
    id: id ?? this.id,
    uuid: uuid ?? this.uuid,
    learnerId: learnerId ?? this.learnerId,
    lexiconId: lexiconId.present ? lexiconId.value : this.lexiconId,
    chunkId: chunkId.present ? chunkId.value : this.chunkId,
    isFavorite: isFavorite ?? this.isFavorite,
    confidenceMarker: confidenceMarker.present
        ? confidenceMarker.value
        : this.confidenceMarker,
    easeFactor: easeFactor ?? this.easeFactor,
    intervalDays: intervalDays ?? this.intervalDays,
    repetitions: repetitions ?? this.repetitions,
    dueAt: dueAt.present ? dueAt.value : this.dueAt,
    lastReviewedAt: lastReviewedAt.present
        ? lastReviewedAt.value
        : this.lastReviewedAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  VocabularyReviewStateData copyWithCompanion(
    VocabularyReviewStateCompanion data,
  ) {
    return VocabularyReviewStateData(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      learnerId: data.learnerId.present ? data.learnerId.value : this.learnerId,
      lexiconId: data.lexiconId.present ? data.lexiconId.value : this.lexiconId,
      chunkId: data.chunkId.present ? data.chunkId.value : this.chunkId,
      isFavorite: data.isFavorite.present
          ? data.isFavorite.value
          : this.isFavorite,
      confidenceMarker: data.confidenceMarker.present
          ? data.confidenceMarker.value
          : this.confidenceMarker,
      easeFactor: data.easeFactor.present
          ? data.easeFactor.value
          : this.easeFactor,
      intervalDays: data.intervalDays.present
          ? data.intervalDays.value
          : this.intervalDays,
      repetitions: data.repetitions.present
          ? data.repetitions.value
          : this.repetitions,
      dueAt: data.dueAt.present ? data.dueAt.value : this.dueAt,
      lastReviewedAt: data.lastReviewedAt.present
          ? data.lastReviewedAt.value
          : this.lastReviewedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VocabularyReviewStateData(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('learnerId: $learnerId, ')
          ..write('lexiconId: $lexiconId, ')
          ..write('chunkId: $chunkId, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('confidenceMarker: $confidenceMarker, ')
          ..write('easeFactor: $easeFactor, ')
          ..write('intervalDays: $intervalDays, ')
          ..write('repetitions: $repetitions, ')
          ..write('dueAt: $dueAt, ')
          ..write('lastReviewedAt: $lastReviewedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    uuid,
    learnerId,
    lexiconId,
    chunkId,
    isFavorite,
    confidenceMarker,
    easeFactor,
    intervalDays,
    repetitions,
    dueAt,
    lastReviewedAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VocabularyReviewStateData &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.learnerId == this.learnerId &&
          other.lexiconId == this.lexiconId &&
          other.chunkId == this.chunkId &&
          other.isFavorite == this.isFavorite &&
          other.confidenceMarker == this.confidenceMarker &&
          other.easeFactor == this.easeFactor &&
          other.intervalDays == this.intervalDays &&
          other.repetitions == this.repetitions &&
          other.dueAt == this.dueAt &&
          other.lastReviewedAt == this.lastReviewedAt &&
          other.updatedAt == this.updatedAt);
}

class VocabularyReviewStateCompanion
    extends UpdateCompanion<VocabularyReviewStateData> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<int> learnerId;
  final Value<String?> lexiconId;
  final Value<String?> chunkId;
  final Value<bool> isFavorite;
  final Value<String?> confidenceMarker;
  final Value<double> easeFactor;
  final Value<int> intervalDays;
  final Value<int> repetitions;
  final Value<DateTime?> dueAt;
  final Value<DateTime?> lastReviewedAt;
  final Value<DateTime> updatedAt;
  const VocabularyReviewStateCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.learnerId = const Value.absent(),
    this.lexiconId = const Value.absent(),
    this.chunkId = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.confidenceMarker = const Value.absent(),
    this.easeFactor = const Value.absent(),
    this.intervalDays = const Value.absent(),
    this.repetitions = const Value.absent(),
    this.dueAt = const Value.absent(),
    this.lastReviewedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  VocabularyReviewStateCompanion.insert({
    this.id = const Value.absent(),
    required String uuid,
    required int learnerId,
    this.lexiconId = const Value.absent(),
    this.chunkId = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.confidenceMarker = const Value.absent(),
    this.easeFactor = const Value.absent(),
    this.intervalDays = const Value.absent(),
    this.repetitions = const Value.absent(),
    this.dueAt = const Value.absent(),
    this.lastReviewedAt = const Value.absent(),
    required DateTime updatedAt,
  }) : uuid = Value(uuid),
       learnerId = Value(learnerId),
       updatedAt = Value(updatedAt);
  static Insertable<VocabularyReviewStateData> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<int>? learnerId,
    Expression<String>? lexiconId,
    Expression<String>? chunkId,
    Expression<bool>? isFavorite,
    Expression<String>? confidenceMarker,
    Expression<double>? easeFactor,
    Expression<int>? intervalDays,
    Expression<int>? repetitions,
    Expression<DateTime>? dueAt,
    Expression<DateTime>? lastReviewedAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (learnerId != null) 'learner_id': learnerId,
      if (lexiconId != null) 'lexicon_id': lexiconId,
      if (chunkId != null) 'chunk_id': chunkId,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (confidenceMarker != null) 'confidence_marker': confidenceMarker,
      if (easeFactor != null) 'ease_factor': easeFactor,
      if (intervalDays != null) 'interval_days': intervalDays,
      if (repetitions != null) 'repetitions': repetitions,
      if (dueAt != null) 'due_at': dueAt,
      if (lastReviewedAt != null) 'last_reviewed_at': lastReviewedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  VocabularyReviewStateCompanion copyWith({
    Value<int>? id,
    Value<String>? uuid,
    Value<int>? learnerId,
    Value<String?>? lexiconId,
    Value<String?>? chunkId,
    Value<bool>? isFavorite,
    Value<String?>? confidenceMarker,
    Value<double>? easeFactor,
    Value<int>? intervalDays,
    Value<int>? repetitions,
    Value<DateTime?>? dueAt,
    Value<DateTime?>? lastReviewedAt,
    Value<DateTime>? updatedAt,
  }) {
    return VocabularyReviewStateCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      learnerId: learnerId ?? this.learnerId,
      lexiconId: lexiconId ?? this.lexiconId,
      chunkId: chunkId ?? this.chunkId,
      isFavorite: isFavorite ?? this.isFavorite,
      confidenceMarker: confidenceMarker ?? this.confidenceMarker,
      easeFactor: easeFactor ?? this.easeFactor,
      intervalDays: intervalDays ?? this.intervalDays,
      repetitions: repetitions ?? this.repetitions,
      dueAt: dueAt ?? this.dueAt,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (learnerId.present) {
      map['learner_id'] = Variable<int>(learnerId.value);
    }
    if (lexiconId.present) {
      map['lexicon_id'] = Variable<String>(lexiconId.value);
    }
    if (chunkId.present) {
      map['chunk_id'] = Variable<String>(chunkId.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (confidenceMarker.present) {
      map['confidence_marker'] = Variable<String>(confidenceMarker.value);
    }
    if (easeFactor.present) {
      map['ease_factor'] = Variable<double>(easeFactor.value);
    }
    if (intervalDays.present) {
      map['interval_days'] = Variable<int>(intervalDays.value);
    }
    if (repetitions.present) {
      map['repetitions'] = Variable<int>(repetitions.value);
    }
    if (dueAt.present) {
      map['due_at'] = Variable<DateTime>(dueAt.value);
    }
    if (lastReviewedAt.present) {
      map['last_reviewed_at'] = Variable<DateTime>(lastReviewedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VocabularyReviewStateCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('learnerId: $learnerId, ')
          ..write('lexiconId: $lexiconId, ')
          ..write('chunkId: $chunkId, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('confidenceMarker: $confidenceMarker, ')
          ..write('easeFactor: $easeFactor, ')
          ..write('intervalDays: $intervalDays, ')
          ..write('repetitions: $repetitions, ')
          ..write('dueAt: $dueAt, ')
          ..write('lastReviewedAt: $lastReviewedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $GrammarReviewStateTable extends GrammarReviewState
    with TableInfo<$GrammarReviewStateTable, GrammarReviewStateData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GrammarReviewStateTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _learnerIdMeta = const VerificationMeta(
    'learnerId',
  );
  @override
  late final GeneratedColumn<int> learnerId = GeneratedColumn<int>(
    'learner_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES learners (id)',
    ),
  );
  static const VerificationMeta _grammarIdMeta = const VerificationMeta(
    'grammarId',
  );
  @override
  late final GeneratedColumn<String> grammarId = GeneratedColumn<String>(
    'grammar_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isFavoriteMeta = const VerificationMeta(
    'isFavorite',
  );
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
    'is_favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_favorite" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _markedReviewedAtMeta = const VerificationMeta(
    'markedReviewedAt',
  );
  @override
  late final GeneratedColumn<DateTime> markedReviewedAt =
      GeneratedColumn<DateTime>(
        'marked_reviewed_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    uuid,
    learnerId,
    grammarId,
    isFavorite,
    markedReviewedAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'grammar_review_state';
  @override
  VerificationContext validateIntegrity(
    Insertable<GrammarReviewStateData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('learner_id')) {
      context.handle(
        _learnerIdMeta,
        learnerId.isAcceptableOrUnknown(data['learner_id']!, _learnerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_learnerIdMeta);
    }
    if (data.containsKey('grammar_id')) {
      context.handle(
        _grammarIdMeta,
        grammarId.isAcceptableOrUnknown(data['grammar_id']!, _grammarIdMeta),
      );
    } else if (isInserting) {
      context.missing(_grammarIdMeta);
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
        _isFavoriteMeta,
        isFavorite.isAcceptableOrUnknown(data['is_favorite']!, _isFavoriteMeta),
      );
    }
    if (data.containsKey('marked_reviewed_at')) {
      context.handle(
        _markedReviewedAtMeta,
        markedReviewedAt.isAcceptableOrUnknown(
          data['marked_reviewed_at']!,
          _markedReviewedAtMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GrammarReviewStateData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GrammarReviewStateData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      learnerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}learner_id'],
      )!,
      grammarId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}grammar_id'],
      )!,
      isFavorite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_favorite'],
      )!,
      markedReviewedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}marked_reviewed_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $GrammarReviewStateTable createAlias(String alias) {
    return $GrammarReviewStateTable(attachedDatabase, alias);
  }
}

class GrammarReviewStateData extends DataClass
    implements Insertable<GrammarReviewStateData> {
  final int id;
  final String uuid;
  final int learnerId;
  final String grammarId;
  final bool isFavorite;
  final DateTime? markedReviewedAt;
  final DateTime updatedAt;
  const GrammarReviewStateData({
    required this.id,
    required this.uuid,
    required this.learnerId,
    required this.grammarId,
    required this.isFavorite,
    this.markedReviewedAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    map['learner_id'] = Variable<int>(learnerId);
    map['grammar_id'] = Variable<String>(grammarId);
    map['is_favorite'] = Variable<bool>(isFavorite);
    if (!nullToAbsent || markedReviewedAt != null) {
      map['marked_reviewed_at'] = Variable<DateTime>(markedReviewedAt);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  GrammarReviewStateCompanion toCompanion(bool nullToAbsent) {
    return GrammarReviewStateCompanion(
      id: Value(id),
      uuid: Value(uuid),
      learnerId: Value(learnerId),
      grammarId: Value(grammarId),
      isFavorite: Value(isFavorite),
      markedReviewedAt: markedReviewedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(markedReviewedAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory GrammarReviewStateData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GrammarReviewStateData(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      learnerId: serializer.fromJson<int>(json['learnerId']),
      grammarId: serializer.fromJson<String>(json['grammarId']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
      markedReviewedAt: serializer.fromJson<DateTime?>(
        json['markedReviewedAt'],
      ),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'learnerId': serializer.toJson<int>(learnerId),
      'grammarId': serializer.toJson<String>(grammarId),
      'isFavorite': serializer.toJson<bool>(isFavorite),
      'markedReviewedAt': serializer.toJson<DateTime?>(markedReviewedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  GrammarReviewStateData copyWith({
    int? id,
    String? uuid,
    int? learnerId,
    String? grammarId,
    bool? isFavorite,
    Value<DateTime?> markedReviewedAt = const Value.absent(),
    DateTime? updatedAt,
  }) => GrammarReviewStateData(
    id: id ?? this.id,
    uuid: uuid ?? this.uuid,
    learnerId: learnerId ?? this.learnerId,
    grammarId: grammarId ?? this.grammarId,
    isFavorite: isFavorite ?? this.isFavorite,
    markedReviewedAt: markedReviewedAt.present
        ? markedReviewedAt.value
        : this.markedReviewedAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  GrammarReviewStateData copyWithCompanion(GrammarReviewStateCompanion data) {
    return GrammarReviewStateData(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      learnerId: data.learnerId.present ? data.learnerId.value : this.learnerId,
      grammarId: data.grammarId.present ? data.grammarId.value : this.grammarId,
      isFavorite: data.isFavorite.present
          ? data.isFavorite.value
          : this.isFavorite,
      markedReviewedAt: data.markedReviewedAt.present
          ? data.markedReviewedAt.value
          : this.markedReviewedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GrammarReviewStateData(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('learnerId: $learnerId, ')
          ..write('grammarId: $grammarId, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('markedReviewedAt: $markedReviewedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    uuid,
    learnerId,
    grammarId,
    isFavorite,
    markedReviewedAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GrammarReviewStateData &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.learnerId == this.learnerId &&
          other.grammarId == this.grammarId &&
          other.isFavorite == this.isFavorite &&
          other.markedReviewedAt == this.markedReviewedAt &&
          other.updatedAt == this.updatedAt);
}

class GrammarReviewStateCompanion
    extends UpdateCompanion<GrammarReviewStateData> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<int> learnerId;
  final Value<String> grammarId;
  final Value<bool> isFavorite;
  final Value<DateTime?> markedReviewedAt;
  final Value<DateTime> updatedAt;
  const GrammarReviewStateCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.learnerId = const Value.absent(),
    this.grammarId = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.markedReviewedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  GrammarReviewStateCompanion.insert({
    this.id = const Value.absent(),
    required String uuid,
    required int learnerId,
    required String grammarId,
    this.isFavorite = const Value.absent(),
    this.markedReviewedAt = const Value.absent(),
    required DateTime updatedAt,
  }) : uuid = Value(uuid),
       learnerId = Value(learnerId),
       grammarId = Value(grammarId),
       updatedAt = Value(updatedAt);
  static Insertable<GrammarReviewStateData> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<int>? learnerId,
    Expression<String>? grammarId,
    Expression<bool>? isFavorite,
    Expression<DateTime>? markedReviewedAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (learnerId != null) 'learner_id': learnerId,
      if (grammarId != null) 'grammar_id': grammarId,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (markedReviewedAt != null) 'marked_reviewed_at': markedReviewedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  GrammarReviewStateCompanion copyWith({
    Value<int>? id,
    Value<String>? uuid,
    Value<int>? learnerId,
    Value<String>? grammarId,
    Value<bool>? isFavorite,
    Value<DateTime?>? markedReviewedAt,
    Value<DateTime>? updatedAt,
  }) {
    return GrammarReviewStateCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      learnerId: learnerId ?? this.learnerId,
      grammarId: grammarId ?? this.grammarId,
      isFavorite: isFavorite ?? this.isFavorite,
      markedReviewedAt: markedReviewedAt ?? this.markedReviewedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (learnerId.present) {
      map['learner_id'] = Variable<int>(learnerId.value);
    }
    if (grammarId.present) {
      map['grammar_id'] = Variable<String>(grammarId.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (markedReviewedAt.present) {
      map['marked_reviewed_at'] = Variable<DateTime>(markedReviewedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GrammarReviewStateCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('learnerId: $learnerId, ')
          ..write('grammarId: $grammarId, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('markedReviewedAt: $markedReviewedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $ContentVersionsTable extends ContentVersions
    with TableInfo<$ContentVersionsTable, ContentVersion> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContentVersionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _contentVersionMeta = const VerificationMeta(
    'contentVersion',
  );
  @override
  late final GeneratedColumn<String> contentVersion = GeneratedColumn<String>(
    'content_version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _schemaVersionMeta = const VerificationMeta(
    'schemaVersion',
  );
  @override
  late final GeneratedColumn<String> schemaVersion = GeneratedColumn<String>(
    'schema_version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _courseIdMeta = const VerificationMeta(
    'courseId',
  );
  @override
  late final GeneratedColumn<String> courseId = GeneratedColumn<String>(
    'course_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _installedAtMeta = const VerificationMeta(
    'installedAt',
  );
  @override
  late final GeneratedColumn<DateTime> installedAt = GeneratedColumn<DateTime>(
    'installed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitIdsJsonMeta = const VerificationMeta(
    'unitIdsJson',
  );
  @override
  late final GeneratedColumn<String> unitIdsJson = GeneratedColumn<String>(
    'unit_ids_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lessonIdsJsonMeta = const VerificationMeta(
    'lessonIdsJson',
  );
  @override
  late final GeneratedColumn<String> lessonIdsJson = GeneratedColumn<String>(
    'lesson_ids_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activityIdsJsonMeta = const VerificationMeta(
    'activityIdsJson',
  );
  @override
  late final GeneratedColumn<String> activityIdsJson = GeneratedColumn<String>(
    'activity_ids_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _canDoIdsJsonMeta = const VerificationMeta(
    'canDoIdsJson',
  );
  @override
  late final GeneratedColumn<String> canDoIdsJson = GeneratedColumn<String>(
    'can_do_ids_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    contentVersion,
    schemaVersion,
    courseId,
    installedAt,
    unitIdsJson,
    lessonIdsJson,
    activityIdsJson,
    canDoIdsJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'content_versions';
  @override
  VerificationContext validateIntegrity(
    Insertable<ContentVersion> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('content_version')) {
      context.handle(
        _contentVersionMeta,
        contentVersion.isAcceptableOrUnknown(
          data['content_version']!,
          _contentVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contentVersionMeta);
    }
    if (data.containsKey('schema_version')) {
      context.handle(
        _schemaVersionMeta,
        schemaVersion.isAcceptableOrUnknown(
          data['schema_version']!,
          _schemaVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_schemaVersionMeta);
    }
    if (data.containsKey('course_id')) {
      context.handle(
        _courseIdMeta,
        courseId.isAcceptableOrUnknown(data['course_id']!, _courseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_courseIdMeta);
    }
    if (data.containsKey('installed_at')) {
      context.handle(
        _installedAtMeta,
        installedAt.isAcceptableOrUnknown(
          data['installed_at']!,
          _installedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_installedAtMeta);
    }
    if (data.containsKey('unit_ids_json')) {
      context.handle(
        _unitIdsJsonMeta,
        unitIdsJson.isAcceptableOrUnknown(
          data['unit_ids_json']!,
          _unitIdsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_unitIdsJsonMeta);
    }
    if (data.containsKey('lesson_ids_json')) {
      context.handle(
        _lessonIdsJsonMeta,
        lessonIdsJson.isAcceptableOrUnknown(
          data['lesson_ids_json']!,
          _lessonIdsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lessonIdsJsonMeta);
    }
    if (data.containsKey('activity_ids_json')) {
      context.handle(
        _activityIdsJsonMeta,
        activityIdsJson.isAcceptableOrUnknown(
          data['activity_ids_json']!,
          _activityIdsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_activityIdsJsonMeta);
    }
    if (data.containsKey('can_do_ids_json')) {
      context.handle(
        _canDoIdsJsonMeta,
        canDoIdsJson.isAcceptableOrUnknown(
          data['can_do_ids_json']!,
          _canDoIdsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_canDoIdsJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ContentVersion map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ContentVersion(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      contentVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_version'],
      )!,
      schemaVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}schema_version'],
      )!,
      courseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}course_id'],
      )!,
      installedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}installed_at'],
      )!,
      unitIdsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit_ids_json'],
      )!,
      lessonIdsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lesson_ids_json'],
      )!,
      activityIdsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}activity_ids_json'],
      )!,
      canDoIdsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}can_do_ids_json'],
      )!,
    );
  }

  @override
  $ContentVersionsTable createAlias(String alias) {
    return $ContentVersionsTable(attachedDatabase, alias);
  }
}

class ContentVersion extends DataClass implements Insertable<ContentVersion> {
  final int id;
  final String contentVersion;
  final String schemaVersion;
  final String courseId;
  final DateTime installedAt;
  final String unitIdsJson;
  final String lessonIdsJson;
  final String activityIdsJson;
  final String canDoIdsJson;
  const ContentVersion({
    required this.id,
    required this.contentVersion,
    required this.schemaVersion,
    required this.courseId,
    required this.installedAt,
    required this.unitIdsJson,
    required this.lessonIdsJson,
    required this.activityIdsJson,
    required this.canDoIdsJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['content_version'] = Variable<String>(contentVersion);
    map['schema_version'] = Variable<String>(schemaVersion);
    map['course_id'] = Variable<String>(courseId);
    map['installed_at'] = Variable<DateTime>(installedAt);
    map['unit_ids_json'] = Variable<String>(unitIdsJson);
    map['lesson_ids_json'] = Variable<String>(lessonIdsJson);
    map['activity_ids_json'] = Variable<String>(activityIdsJson);
    map['can_do_ids_json'] = Variable<String>(canDoIdsJson);
    return map;
  }

  ContentVersionsCompanion toCompanion(bool nullToAbsent) {
    return ContentVersionsCompanion(
      id: Value(id),
      contentVersion: Value(contentVersion),
      schemaVersion: Value(schemaVersion),
      courseId: Value(courseId),
      installedAt: Value(installedAt),
      unitIdsJson: Value(unitIdsJson),
      lessonIdsJson: Value(lessonIdsJson),
      activityIdsJson: Value(activityIdsJson),
      canDoIdsJson: Value(canDoIdsJson),
    );
  }

  factory ContentVersion.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ContentVersion(
      id: serializer.fromJson<int>(json['id']),
      contentVersion: serializer.fromJson<String>(json['contentVersion']),
      schemaVersion: serializer.fromJson<String>(json['schemaVersion']),
      courseId: serializer.fromJson<String>(json['courseId']),
      installedAt: serializer.fromJson<DateTime>(json['installedAt']),
      unitIdsJson: serializer.fromJson<String>(json['unitIdsJson']),
      lessonIdsJson: serializer.fromJson<String>(json['lessonIdsJson']),
      activityIdsJson: serializer.fromJson<String>(json['activityIdsJson']),
      canDoIdsJson: serializer.fromJson<String>(json['canDoIdsJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'contentVersion': serializer.toJson<String>(contentVersion),
      'schemaVersion': serializer.toJson<String>(schemaVersion),
      'courseId': serializer.toJson<String>(courseId),
      'installedAt': serializer.toJson<DateTime>(installedAt),
      'unitIdsJson': serializer.toJson<String>(unitIdsJson),
      'lessonIdsJson': serializer.toJson<String>(lessonIdsJson),
      'activityIdsJson': serializer.toJson<String>(activityIdsJson),
      'canDoIdsJson': serializer.toJson<String>(canDoIdsJson),
    };
  }

  ContentVersion copyWith({
    int? id,
    String? contentVersion,
    String? schemaVersion,
    String? courseId,
    DateTime? installedAt,
    String? unitIdsJson,
    String? lessonIdsJson,
    String? activityIdsJson,
    String? canDoIdsJson,
  }) => ContentVersion(
    id: id ?? this.id,
    contentVersion: contentVersion ?? this.contentVersion,
    schemaVersion: schemaVersion ?? this.schemaVersion,
    courseId: courseId ?? this.courseId,
    installedAt: installedAt ?? this.installedAt,
    unitIdsJson: unitIdsJson ?? this.unitIdsJson,
    lessonIdsJson: lessonIdsJson ?? this.lessonIdsJson,
    activityIdsJson: activityIdsJson ?? this.activityIdsJson,
    canDoIdsJson: canDoIdsJson ?? this.canDoIdsJson,
  );
  ContentVersion copyWithCompanion(ContentVersionsCompanion data) {
    return ContentVersion(
      id: data.id.present ? data.id.value : this.id,
      contentVersion: data.contentVersion.present
          ? data.contentVersion.value
          : this.contentVersion,
      schemaVersion: data.schemaVersion.present
          ? data.schemaVersion.value
          : this.schemaVersion,
      courseId: data.courseId.present ? data.courseId.value : this.courseId,
      installedAt: data.installedAt.present
          ? data.installedAt.value
          : this.installedAt,
      unitIdsJson: data.unitIdsJson.present
          ? data.unitIdsJson.value
          : this.unitIdsJson,
      lessonIdsJson: data.lessonIdsJson.present
          ? data.lessonIdsJson.value
          : this.lessonIdsJson,
      activityIdsJson: data.activityIdsJson.present
          ? data.activityIdsJson.value
          : this.activityIdsJson,
      canDoIdsJson: data.canDoIdsJson.present
          ? data.canDoIdsJson.value
          : this.canDoIdsJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ContentVersion(')
          ..write('id: $id, ')
          ..write('contentVersion: $contentVersion, ')
          ..write('schemaVersion: $schemaVersion, ')
          ..write('courseId: $courseId, ')
          ..write('installedAt: $installedAt, ')
          ..write('unitIdsJson: $unitIdsJson, ')
          ..write('lessonIdsJson: $lessonIdsJson, ')
          ..write('activityIdsJson: $activityIdsJson, ')
          ..write('canDoIdsJson: $canDoIdsJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    contentVersion,
    schemaVersion,
    courseId,
    installedAt,
    unitIdsJson,
    lessonIdsJson,
    activityIdsJson,
    canDoIdsJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ContentVersion &&
          other.id == this.id &&
          other.contentVersion == this.contentVersion &&
          other.schemaVersion == this.schemaVersion &&
          other.courseId == this.courseId &&
          other.installedAt == this.installedAt &&
          other.unitIdsJson == this.unitIdsJson &&
          other.lessonIdsJson == this.lessonIdsJson &&
          other.activityIdsJson == this.activityIdsJson &&
          other.canDoIdsJson == this.canDoIdsJson);
}

class ContentVersionsCompanion extends UpdateCompanion<ContentVersion> {
  final Value<int> id;
  final Value<String> contentVersion;
  final Value<String> schemaVersion;
  final Value<String> courseId;
  final Value<DateTime> installedAt;
  final Value<String> unitIdsJson;
  final Value<String> lessonIdsJson;
  final Value<String> activityIdsJson;
  final Value<String> canDoIdsJson;
  const ContentVersionsCompanion({
    this.id = const Value.absent(),
    this.contentVersion = const Value.absent(),
    this.schemaVersion = const Value.absent(),
    this.courseId = const Value.absent(),
    this.installedAt = const Value.absent(),
    this.unitIdsJson = const Value.absent(),
    this.lessonIdsJson = const Value.absent(),
    this.activityIdsJson = const Value.absent(),
    this.canDoIdsJson = const Value.absent(),
  });
  ContentVersionsCompanion.insert({
    this.id = const Value.absent(),
    required String contentVersion,
    required String schemaVersion,
    required String courseId,
    required DateTime installedAt,
    required String unitIdsJson,
    required String lessonIdsJson,
    required String activityIdsJson,
    required String canDoIdsJson,
  }) : contentVersion = Value(contentVersion),
       schemaVersion = Value(schemaVersion),
       courseId = Value(courseId),
       installedAt = Value(installedAt),
       unitIdsJson = Value(unitIdsJson),
       lessonIdsJson = Value(lessonIdsJson),
       activityIdsJson = Value(activityIdsJson),
       canDoIdsJson = Value(canDoIdsJson);
  static Insertable<ContentVersion> custom({
    Expression<int>? id,
    Expression<String>? contentVersion,
    Expression<String>? schemaVersion,
    Expression<String>? courseId,
    Expression<DateTime>? installedAt,
    Expression<String>? unitIdsJson,
    Expression<String>? lessonIdsJson,
    Expression<String>? activityIdsJson,
    Expression<String>? canDoIdsJson,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (contentVersion != null) 'content_version': contentVersion,
      if (schemaVersion != null) 'schema_version': schemaVersion,
      if (courseId != null) 'course_id': courseId,
      if (installedAt != null) 'installed_at': installedAt,
      if (unitIdsJson != null) 'unit_ids_json': unitIdsJson,
      if (lessonIdsJson != null) 'lesson_ids_json': lessonIdsJson,
      if (activityIdsJson != null) 'activity_ids_json': activityIdsJson,
      if (canDoIdsJson != null) 'can_do_ids_json': canDoIdsJson,
    });
  }

  ContentVersionsCompanion copyWith({
    Value<int>? id,
    Value<String>? contentVersion,
    Value<String>? schemaVersion,
    Value<String>? courseId,
    Value<DateTime>? installedAt,
    Value<String>? unitIdsJson,
    Value<String>? lessonIdsJson,
    Value<String>? activityIdsJson,
    Value<String>? canDoIdsJson,
  }) {
    return ContentVersionsCompanion(
      id: id ?? this.id,
      contentVersion: contentVersion ?? this.contentVersion,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      courseId: courseId ?? this.courseId,
      installedAt: installedAt ?? this.installedAt,
      unitIdsJson: unitIdsJson ?? this.unitIdsJson,
      lessonIdsJson: lessonIdsJson ?? this.lessonIdsJson,
      activityIdsJson: activityIdsJson ?? this.activityIdsJson,
      canDoIdsJson: canDoIdsJson ?? this.canDoIdsJson,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (contentVersion.present) {
      map['content_version'] = Variable<String>(contentVersion.value);
    }
    if (schemaVersion.present) {
      map['schema_version'] = Variable<String>(schemaVersion.value);
    }
    if (courseId.present) {
      map['course_id'] = Variable<String>(courseId.value);
    }
    if (installedAt.present) {
      map['installed_at'] = Variable<DateTime>(installedAt.value);
    }
    if (unitIdsJson.present) {
      map['unit_ids_json'] = Variable<String>(unitIdsJson.value);
    }
    if (lessonIdsJson.present) {
      map['lesson_ids_json'] = Variable<String>(lessonIdsJson.value);
    }
    if (activityIdsJson.present) {
      map['activity_ids_json'] = Variable<String>(activityIdsJson.value);
    }
    if (canDoIdsJson.present) {
      map['can_do_ids_json'] = Variable<String>(canDoIdsJson.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContentVersionsCompanion(')
          ..write('id: $id, ')
          ..write('contentVersion: $contentVersion, ')
          ..write('schemaVersion: $schemaVersion, ')
          ..write('courseId: $courseId, ')
          ..write('installedAt: $installedAt, ')
          ..write('unitIdsJson: $unitIdsJson, ')
          ..write('lessonIdsJson: $lessonIdsJson, ')
          ..write('activityIdsJson: $activityIdsJson, ')
          ..write('canDoIdsJson: $canDoIdsJson')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LearnersTable learners = $LearnersTable(this);
  late final $CourseEnrolmentsTable courseEnrolments = $CourseEnrolmentsTable(
    this,
  );
  late final $UnitProgressTable unitProgress = $UnitProgressTable(this);
  late final $LessonProgressTable lessonProgress = $LessonProgressTable(this);
  late final $ActivityAttemptsTable activityAttempts = $ActivityAttemptsTable(
    this,
  );
  late final $ActivityAttemptCanDosTable activityAttemptCanDos =
      $ActivityAttemptCanDosTable(this);
  late final $PlacementAttemptsTable placementAttempts =
      $PlacementAttemptsTable(this);
  late final $FinalMissionAttemptsTable finalMissionAttempts =
      $FinalMissionAttemptsTable(this);
  late final $FinalAssessmentAttemptsTable finalAssessmentAttempts =
      $FinalAssessmentAttemptsTable(this);
  late final $VocabularyReviewStateTable vocabularyReviewState =
      $VocabularyReviewStateTable(this);
  late final $GrammarReviewStateTable grammarReviewState =
      $GrammarReviewStateTable(this);
  late final $ContentVersionsTable contentVersions = $ContentVersionsTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    learners,
    courseEnrolments,
    unitProgress,
    lessonProgress,
    activityAttempts,
    activityAttemptCanDos,
    placementAttempts,
    finalMissionAttempts,
    finalAssessmentAttempts,
    vocabularyReviewState,
    grammarReviewState,
    contentVersions,
  ];
}

typedef $$LearnersTableCreateCompanionBuilder = LearnersCompanion Function({
  Value<int> id,
  required String uuid,
  Value<String?> name,
  Value<String> nativeLanguage,
  Value<String> targetLanguage,
  required DateTime createdAt,
  Value<bool> isActive,
});
typedef $$LearnersTableUpdateCompanionBuilder = LearnersCompanion Function({
  Value<int> id,
  Value<String> uuid,
  Value<String?> name,
  Value<String> nativeLanguage,
  Value<String> targetLanguage,
  Value<DateTime> createdAt,
  Value<bool> isActive,
});

final class $$LearnersTableReferences
    extends BaseReferences<_$AppDatabase, $LearnersTable, Learner> {
  $$LearnersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$CourseEnrolmentsTable, List<CourseEnrolment>>
  _courseEnrolmentsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.courseEnrolments,
    aliasName: 'learners__id__course_enrolments__learner_id',
  );

  $$CourseEnrolmentsTableProcessedTableManager get courseEnrolmentsRefs {
    final manager = $$CourseEnrolmentsTableTableManager(
      $_db,
      $_db.courseEnrolments,
    ).filter((f) => f.learnerId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _courseEnrolmentsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$UnitProgressTable, List<UnitProgressData>>
  _unitProgressRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.unitProgress,
    aliasName: 'learners__id__unit_progress__learner_id',
  );

  $$UnitProgressTableProcessedTableManager get unitProgressRefs {
    final manager = $$UnitProgressTableTableManager(
      $_db,
      $_db.unitProgress,
    ).filter((f) => f.learnerId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_unitProgressRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$LessonProgressTable, List<LessonProgressData>>
  _lessonProgressRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.lessonProgress,
    aliasName: 'learners__id__lesson_progress__learner_id',
  );

  $$LessonProgressTableProcessedTableManager get lessonProgressRefs {
    final manager = $$LessonProgressTableTableManager(
      $_db,
      $_db.lessonProgress,
    ).filter((f) => f.learnerId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_lessonProgressRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ActivityAttemptsTable, List<ActivityAttempt>>
  _activityAttemptsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.activityAttempts,
    aliasName: 'learners__id__activity_attempts__learner_id',
  );

  $$ActivityAttemptsTableProcessedTableManager get activityAttemptsRefs {
    final manager = $$ActivityAttemptsTableTableManager(
      $_db,
      $_db.activityAttempts,
    ).filter((f) => f.learnerId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _activityAttemptsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PlacementAttemptsTable, List<PlacementAttempt>>
  _placementAttemptsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.placementAttempts,
        aliasName: 'learners__id__placement_attempts__learner_id',
      );

  $$PlacementAttemptsTableProcessedTableManager get placementAttemptsRefs {
    final manager = $$PlacementAttemptsTableTableManager(
      $_db,
      $_db.placementAttempts,
    ).filter((f) => f.learnerId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _placementAttemptsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $FinalMissionAttemptsTable,
    List<FinalMissionAttempt>
  >
  _finalMissionAttemptsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.finalMissionAttempts,
        aliasName: 'learners__id__final_mission_attempts__learner_id',
      );

  $$FinalMissionAttemptsTableProcessedTableManager
  get finalMissionAttemptsRefs {
    final manager = $$FinalMissionAttemptsTableTableManager(
      $_db,
      $_db.finalMissionAttempts,
    ).filter((f) => f.learnerId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _finalMissionAttemptsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $FinalAssessmentAttemptsTable,
    List<FinalAssessmentAttempt>
  >
  _finalAssessmentAttemptsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.finalAssessmentAttempts,
        aliasName: 'learners__id__final_assessment_attempts__learner_id',
      );

  $$FinalAssessmentAttemptsTableProcessedTableManager
  get finalAssessmentAttemptsRefs {
    final manager = $$FinalAssessmentAttemptsTableTableManager(
      $_db,
      $_db.finalAssessmentAttempts,
    ).filter((f) => f.learnerId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _finalAssessmentAttemptsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $VocabularyReviewStateTable,
    List<VocabularyReviewStateData>
  >
  _vocabularyReviewStateRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.vocabularyReviewState,
        aliasName: 'learners__id__vocabulary_review_state__learner_id',
      );

  $$VocabularyReviewStateTableProcessedTableManager
  get vocabularyReviewStateRefs {
    final manager = $$VocabularyReviewStateTableTableManager(
      $_db,
      $_db.vocabularyReviewState,
    ).filter((f) => f.learnerId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _vocabularyReviewStateRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $GrammarReviewStateTable,
    List<GrammarReviewStateData>
  >
  _grammarReviewStateRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.grammarReviewState,
        aliasName: 'learners__id__grammar_review_state__learner_id',
      );

  $$GrammarReviewStateTableProcessedTableManager get grammarReviewStateRefs {
    final manager = $$GrammarReviewStateTableTableManager(
      $_db,
      $_db.grammarReviewState,
    ).filter((f) => f.learnerId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _grammarReviewStateRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$LearnersTableFilterComposer
    extends Composer<_$AppDatabase, $LearnersTable> {
  $$LearnersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nativeLanguage => $composableBuilder(
    column: $table.nativeLanguage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetLanguage => $composableBuilder(
    column: $table.targetLanguage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> courseEnrolmentsRefs(
    Expression<bool> Function($$CourseEnrolmentsTableFilterComposer f) f,
  ) {
    final $$CourseEnrolmentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.courseEnrolments,
      getReferencedColumn: (t) => t.learnerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CourseEnrolmentsTableFilterComposer(
            $db: $db,
            $table: $db.courseEnrolments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> unitProgressRefs(
    Expression<bool> Function($$UnitProgressTableFilterComposer f) f,
  ) {
    final $$UnitProgressTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.unitProgress,
      getReferencedColumn: (t) => t.learnerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UnitProgressTableFilterComposer(
            $db: $db,
            $table: $db.unitProgress,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> lessonProgressRefs(
    Expression<bool> Function($$LessonProgressTableFilterComposer f) f,
  ) {
    final $$LessonProgressTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.lessonProgress,
      getReferencedColumn: (t) => t.learnerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LessonProgressTableFilterComposer(
            $db: $db,
            $table: $db.lessonProgress,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> activityAttemptsRefs(
    Expression<bool> Function($$ActivityAttemptsTableFilterComposer f) f,
  ) {
    final $$ActivityAttemptsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.activityAttempts,
      getReferencedColumn: (t) => t.learnerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ActivityAttemptsTableFilterComposer(
            $db: $db,
            $table: $db.activityAttempts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> placementAttemptsRefs(
    Expression<bool> Function($$PlacementAttemptsTableFilterComposer f) f,
  ) {
    final $$PlacementAttemptsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.placementAttempts,
      getReferencedColumn: (t) => t.learnerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlacementAttemptsTableFilterComposer(
            $db: $db,
            $table: $db.placementAttempts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> finalMissionAttemptsRefs(
    Expression<bool> Function($$FinalMissionAttemptsTableFilterComposer f) f,
  ) {
    final $$FinalMissionAttemptsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.finalMissionAttempts,
      getReferencedColumn: (t) => t.learnerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FinalMissionAttemptsTableFilterComposer(
            $db: $db,
            $table: $db.finalMissionAttempts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> finalAssessmentAttemptsRefs(
    Expression<bool> Function($$FinalAssessmentAttemptsTableFilterComposer f) f,
  ) {
    final $$FinalAssessmentAttemptsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.finalAssessmentAttempts,
          getReferencedColumn: (t) => t.learnerId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$FinalAssessmentAttemptsTableFilterComposer(
                $db: $db,
                $table: $db.finalAssessmentAttempts,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> vocabularyReviewStateRefs(
    Expression<bool> Function($$VocabularyReviewStateTableFilterComposer f) f,
  ) {
    final $$VocabularyReviewStateTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.vocabularyReviewState,
          getReferencedColumn: (t) => t.learnerId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$VocabularyReviewStateTableFilterComposer(
                $db: $db,
                $table: $db.vocabularyReviewState,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> grammarReviewStateRefs(
    Expression<bool> Function($$GrammarReviewStateTableFilterComposer f) f,
  ) {
    final $$GrammarReviewStateTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.grammarReviewState,
      getReferencedColumn: (t) => t.learnerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GrammarReviewStateTableFilterComposer(
            $db: $db,
            $table: $db.grammarReviewState,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LearnersTableOrderingComposer
    extends Composer<_$AppDatabase, $LearnersTable> {
  $$LearnersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nativeLanguage => $composableBuilder(
    column: $table.nativeLanguage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetLanguage => $composableBuilder(
    column: $table.targetLanguage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LearnersTableAnnotationComposer
    extends Composer<_$AppDatabase, $LearnersTable> {
  $$LearnersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get nativeLanguage => $composableBuilder(
    column: $table.nativeLanguage,
    builder: (column) => column,
  );

  GeneratedColumn<String> get targetLanguage => $composableBuilder(
    column: $table.targetLanguage,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  Expression<T> courseEnrolmentsRefs<T extends Object>(
    Expression<T> Function($$CourseEnrolmentsTableAnnotationComposer a) f,
  ) {
    final $$CourseEnrolmentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.courseEnrolments,
      getReferencedColumn: (t) => t.learnerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CourseEnrolmentsTableAnnotationComposer(
            $db: $db,
            $table: $db.courseEnrolments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> unitProgressRefs<T extends Object>(
    Expression<T> Function($$UnitProgressTableAnnotationComposer a) f,
  ) {
    final $$UnitProgressTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.unitProgress,
      getReferencedColumn: (t) => t.learnerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UnitProgressTableAnnotationComposer(
            $db: $db,
            $table: $db.unitProgress,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> lessonProgressRefs<T extends Object>(
    Expression<T> Function($$LessonProgressTableAnnotationComposer a) f,
  ) {
    final $$LessonProgressTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.lessonProgress,
      getReferencedColumn: (t) => t.learnerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LessonProgressTableAnnotationComposer(
            $db: $db,
            $table: $db.lessonProgress,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> activityAttemptsRefs<T extends Object>(
    Expression<T> Function($$ActivityAttemptsTableAnnotationComposer a) f,
  ) {
    final $$ActivityAttemptsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.activityAttempts,
      getReferencedColumn: (t) => t.learnerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ActivityAttemptsTableAnnotationComposer(
            $db: $db,
            $table: $db.activityAttempts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> placementAttemptsRefs<T extends Object>(
    Expression<T> Function($$PlacementAttemptsTableAnnotationComposer a) f,
  ) {
    final $$PlacementAttemptsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.placementAttempts,
          getReferencedColumn: (t) => t.learnerId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PlacementAttemptsTableAnnotationComposer(
                $db: $db,
                $table: $db.placementAttempts,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> finalMissionAttemptsRefs<T extends Object>(
    Expression<T> Function($$FinalMissionAttemptsTableAnnotationComposer a) f,
  ) {
    final $$FinalMissionAttemptsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.finalMissionAttempts,
          getReferencedColumn: (t) => t.learnerId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$FinalMissionAttemptsTableAnnotationComposer(
                $db: $db,
                $table: $db.finalMissionAttempts,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> finalAssessmentAttemptsRefs<T extends Object>(
    Expression<T> Function($$FinalAssessmentAttemptsTableAnnotationComposer a)
    f,
  ) {
    final $$FinalAssessmentAttemptsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.finalAssessmentAttempts,
          getReferencedColumn: (t) => t.learnerId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$FinalAssessmentAttemptsTableAnnotationComposer(
                $db: $db,
                $table: $db.finalAssessmentAttempts,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> vocabularyReviewStateRefs<T extends Object>(
    Expression<T> Function($$VocabularyReviewStateTableAnnotationComposer a) f,
  ) {
    final $$VocabularyReviewStateTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.vocabularyReviewState,
          getReferencedColumn: (t) => t.learnerId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$VocabularyReviewStateTableAnnotationComposer(
                $db: $db,
                $table: $db.vocabularyReviewState,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> grammarReviewStateRefs<T extends Object>(
    Expression<T> Function($$GrammarReviewStateTableAnnotationComposer a) f,
  ) {
    final $$GrammarReviewStateTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.grammarReviewState,
          getReferencedColumn: (t) => t.learnerId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$GrammarReviewStateTableAnnotationComposer(
                $db: $db,
                $table: $db.grammarReviewState,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$LearnersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LearnersTable,
          Learner,
          $$LearnersTableFilterComposer,
          $$LearnersTableOrderingComposer,
          $$LearnersTableAnnotationComposer,
          $$LearnersTableCreateCompanionBuilder,
          $$LearnersTableUpdateCompanionBuilder,
          (Learner, $$LearnersTableReferences),
          Learner,
          PrefetchHooks Function({
            bool courseEnrolmentsRefs,
            bool unitProgressRefs,
            bool lessonProgressRefs,
            bool activityAttemptsRefs,
            bool placementAttemptsRefs,
            bool finalMissionAttemptsRefs,
            bool finalAssessmentAttemptsRefs,
            bool vocabularyReviewStateRefs,
            bool grammarReviewStateRefs,
          })
        > {
  $$LearnersTableTableManager(_$AppDatabase db, $LearnersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LearnersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LearnersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LearnersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<String> nativeLanguage = const Value.absent(),
                Value<String> targetLanguage = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
              }) => LearnersCompanion(
                id: id,
                uuid: uuid,
                name: name,
                nativeLanguage: nativeLanguage,
                targetLanguage: targetLanguage,
                createdAt: createdAt,
                isActive: isActive,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String uuid,
                Value<String?> name = const Value.absent(),
                Value<String> nativeLanguage = const Value.absent(),
                Value<String> targetLanguage = const Value.absent(),
                required DateTime createdAt,
                Value<bool> isActive = const Value.absent(),
              }) => LearnersCompanion.insert(
                id: id,
                uuid: uuid,
                name: name,
                nativeLanguage: nativeLanguage,
                targetLanguage: targetLanguage,
                createdAt: createdAt,
                isActive: isActive,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LearnersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                courseEnrolmentsRefs = false,
                unitProgressRefs = false,
                lessonProgressRefs = false,
                activityAttemptsRefs = false,
                placementAttemptsRefs = false,
                finalMissionAttemptsRefs = false,
                finalAssessmentAttemptsRefs = false,
                vocabularyReviewStateRefs = false,
                grammarReviewStateRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (courseEnrolmentsRefs) db.courseEnrolments,
                    if (unitProgressRefs) db.unitProgress,
                    if (lessonProgressRefs) db.lessonProgress,
                    if (activityAttemptsRefs) db.activityAttempts,
                    if (placementAttemptsRefs) db.placementAttempts,
                    if (finalMissionAttemptsRefs) db.finalMissionAttempts,
                    if (finalAssessmentAttemptsRefs) db.finalAssessmentAttempts,
                    if (vocabularyReviewStateRefs) db.vocabularyReviewState,
                    if (grammarReviewStateRefs) db.grammarReviewState,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (courseEnrolmentsRefs)
                        await $_getPrefetchedData<
                          Learner,
                          $LearnersTable,
                          CourseEnrolment
                        >(
                          currentTable: table,
                          referencedTable: $$LearnersTableReferences
                              ._courseEnrolmentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LearnersTableReferences(
                                db,
                                table,
                                p0,
                              ).courseEnrolmentsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.learnerId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (unitProgressRefs)
                        await $_getPrefetchedData<
                          Learner,
                          $LearnersTable,
                          UnitProgressData
                        >(
                          currentTable: table,
                          referencedTable: $$LearnersTableReferences
                              ._unitProgressRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LearnersTableReferences(
                                db,
                                table,
                                p0,
                              ).unitProgressRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.learnerId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (lessonProgressRefs)
                        await $_getPrefetchedData<
                          Learner,
                          $LearnersTable,
                          LessonProgressData
                        >(
                          currentTable: table,
                          referencedTable: $$LearnersTableReferences
                              ._lessonProgressRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LearnersTableReferences(
                                db,
                                table,
                                p0,
                              ).lessonProgressRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.learnerId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (activityAttemptsRefs)
                        await $_getPrefetchedData<
                          Learner,
                          $LearnersTable,
                          ActivityAttempt
                        >(
                          currentTable: table,
                          referencedTable: $$LearnersTableReferences
                              ._activityAttemptsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LearnersTableReferences(
                                db,
                                table,
                                p0,
                              ).activityAttemptsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.learnerId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (placementAttemptsRefs)
                        await $_getPrefetchedData<
                          Learner,
                          $LearnersTable,
                          PlacementAttempt
                        >(
                          currentTable: table,
                          referencedTable: $$LearnersTableReferences
                              ._placementAttemptsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LearnersTableReferences(
                                db,
                                table,
                                p0,
                              ).placementAttemptsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.learnerId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (finalMissionAttemptsRefs)
                        await $_getPrefetchedData<
                          Learner,
                          $LearnersTable,
                          FinalMissionAttempt
                        >(
                          currentTable: table,
                          referencedTable: $$LearnersTableReferences
                              ._finalMissionAttemptsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LearnersTableReferences(
                                db,
                                table,
                                p0,
                              ).finalMissionAttemptsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.learnerId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (finalAssessmentAttemptsRefs)
                        await $_getPrefetchedData<
                          Learner,
                          $LearnersTable,
                          FinalAssessmentAttempt
                        >(
                          currentTable: table,
                          referencedTable: $$LearnersTableReferences
                              ._finalAssessmentAttemptsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LearnersTableReferences(
                                db,
                                table,
                                p0,
                              ).finalAssessmentAttemptsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.learnerId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (vocabularyReviewStateRefs)
                        await $_getPrefetchedData<
                          Learner,
                          $LearnersTable,
                          VocabularyReviewStateData
                        >(
                          currentTable: table,
                          referencedTable: $$LearnersTableReferences
                              ._vocabularyReviewStateRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LearnersTableReferences(
                                db,
                                table,
                                p0,
                              ).vocabularyReviewStateRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.learnerId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (grammarReviewStateRefs)
                        await $_getPrefetchedData<
                          Learner,
                          $LearnersTable,
                          GrammarReviewStateData
                        >(
                          currentTable: table,
                          referencedTable: $$LearnersTableReferences
                              ._grammarReviewStateRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LearnersTableReferences(
                                db,
                                table,
                                p0,
                              ).grammarReviewStateRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.learnerId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$LearnersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LearnersTable,
      Learner,
      $$LearnersTableFilterComposer,
      $$LearnersTableOrderingComposer,
      $$LearnersTableAnnotationComposer,
      $$LearnersTableCreateCompanionBuilder,
      $$LearnersTableUpdateCompanionBuilder,
      (Learner, $$LearnersTableReferences),
      Learner,
      PrefetchHooks Function({
        bool courseEnrolmentsRefs,
        bool unitProgressRefs,
        bool lessonProgressRefs,
        bool activityAttemptsRefs,
        bool placementAttemptsRefs,
        bool finalMissionAttemptsRefs,
        bool finalAssessmentAttemptsRefs,
        bool vocabularyReviewStateRefs,
        bool grammarReviewStateRefs,
      })
    >;
typedef $$CourseEnrolmentsTableCreateCompanionBuilder =
    CourseEnrolmentsCompanion Function({
      Value<int> id,
      required String uuid,
      required int learnerId,
      required String courseId,
      required String contentVersion,
      required DateTime enrolledAt,
      required String status,
    });
typedef $$CourseEnrolmentsTableUpdateCompanionBuilder =
    CourseEnrolmentsCompanion Function({
      Value<int> id,
      Value<String> uuid,
      Value<int> learnerId,
      Value<String> courseId,
      Value<String> contentVersion,
      Value<DateTime> enrolledAt,
      Value<String> status,
    });

final class $$CourseEnrolmentsTableReferences
    extends
        BaseReferences<_$AppDatabase, $CourseEnrolmentsTable, CourseEnrolment> {
  $$CourseEnrolmentsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $LearnersTable _learnerIdTable(_$AppDatabase db) =>
      db.learners.createAlias('course_enrolments__learner_id__learners__id');

  $$LearnersTableProcessedTableManager get learnerId {
    final $_column = $_itemColumn<int>('learner_id')!;

    final manager = $$LearnersTableTableManager(
      $_db,
      $_db.learners,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_learnerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CourseEnrolmentsTableFilterComposer
    extends Composer<_$AppDatabase, $CourseEnrolmentsTable> {
  $$CourseEnrolmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get courseId => $composableBuilder(
    column: $table.courseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentVersion => $composableBuilder(
    column: $table.contentVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get enrolledAt => $composableBuilder(
    column: $table.enrolledAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  $$LearnersTableFilterComposer get learnerId {
    final $$LearnersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.learnerId,
      referencedTable: $db.learners,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LearnersTableFilterComposer(
            $db: $db,
            $table: $db.learners,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CourseEnrolmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $CourseEnrolmentsTable> {
  $$CourseEnrolmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get courseId => $composableBuilder(
    column: $table.courseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentVersion => $composableBuilder(
    column: $table.contentVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get enrolledAt => $composableBuilder(
    column: $table.enrolledAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  $$LearnersTableOrderingComposer get learnerId {
    final $$LearnersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.learnerId,
      referencedTable: $db.learners,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LearnersTableOrderingComposer(
            $db: $db,
            $table: $db.learners,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CourseEnrolmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CourseEnrolmentsTable> {
  $$CourseEnrolmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get courseId =>
      $composableBuilder(column: $table.courseId, builder: (column) => column);

  GeneratedColumn<String> get contentVersion => $composableBuilder(
    column: $table.contentVersion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get enrolledAt => $composableBuilder(
    column: $table.enrolledAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  $$LearnersTableAnnotationComposer get learnerId {
    final $$LearnersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.learnerId,
      referencedTable: $db.learners,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LearnersTableAnnotationComposer(
            $db: $db,
            $table: $db.learners,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CourseEnrolmentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CourseEnrolmentsTable,
          CourseEnrolment,
          $$CourseEnrolmentsTableFilterComposer,
          $$CourseEnrolmentsTableOrderingComposer,
          $$CourseEnrolmentsTableAnnotationComposer,
          $$CourseEnrolmentsTableCreateCompanionBuilder,
          $$CourseEnrolmentsTableUpdateCompanionBuilder,
          (CourseEnrolment, $$CourseEnrolmentsTableReferences),
          CourseEnrolment,
          PrefetchHooks Function({bool learnerId})
        > {
  $$CourseEnrolmentsTableTableManager(
    _$AppDatabase db,
    $CourseEnrolmentsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CourseEnrolmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CourseEnrolmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CourseEnrolmentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<int> learnerId = const Value.absent(),
                Value<String> courseId = const Value.absent(),
                Value<String> contentVersion = const Value.absent(),
                Value<DateTime> enrolledAt = const Value.absent(),
                Value<String> status = const Value.absent(),
              }) => CourseEnrolmentsCompanion(
                id: id,
                uuid: uuid,
                learnerId: learnerId,
                courseId: courseId,
                contentVersion: contentVersion,
                enrolledAt: enrolledAt,
                status: status,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String uuid,
                required int learnerId,
                required String courseId,
                required String contentVersion,
                required DateTime enrolledAt,
                required String status,
              }) => CourseEnrolmentsCompanion.insert(
                id: id,
                uuid: uuid,
                learnerId: learnerId,
                courseId: courseId,
                contentVersion: contentVersion,
                enrolledAt: enrolledAt,
                status: status,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CourseEnrolmentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({learnerId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (learnerId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.learnerId,
                        referencedTable: $$CourseEnrolmentsTableReferences
                            ._learnerIdTable(db),
                        referencedColumn: $$CourseEnrolmentsTableReferences
                            ._learnerIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CourseEnrolmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CourseEnrolmentsTable,
      CourseEnrolment,
      $$CourseEnrolmentsTableFilterComposer,
      $$CourseEnrolmentsTableOrderingComposer,
      $$CourseEnrolmentsTableAnnotationComposer,
      $$CourseEnrolmentsTableCreateCompanionBuilder,
      $$CourseEnrolmentsTableUpdateCompanionBuilder,
      (CourseEnrolment, $$CourseEnrolmentsTableReferences),
      CourseEnrolment,
      PrefetchHooks Function({bool learnerId})
    >;
typedef $$UnitProgressTableCreateCompanionBuilder =
    UnitProgressCompanion Function({
      Value<int> id,
      required String uuid,
      required int learnerId,
      required String unitId,
      required String state,
      Value<DateTime?> lastActivityAt,
      Value<DateTime?> masteredAt,
      Value<bool> isContentStale,
      required DateTime updatedAt,
    });
typedef $$UnitProgressTableUpdateCompanionBuilder =
    UnitProgressCompanion Function({
      Value<int> id,
      Value<String> uuid,
      Value<int> learnerId,
      Value<String> unitId,
      Value<String> state,
      Value<DateTime?> lastActivityAt,
      Value<DateTime?> masteredAt,
      Value<bool> isContentStale,
      Value<DateTime> updatedAt,
    });

final class $$UnitProgressTableReferences
    extends
        BaseReferences<_$AppDatabase, $UnitProgressTable, UnitProgressData> {
  $$UnitProgressTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $LearnersTable _learnerIdTable(_$AppDatabase db) =>
      db.learners.createAlias('unit_progress__learner_id__learners__id');

  $$LearnersTableProcessedTableManager get learnerId {
    final $_column = $_itemColumn<int>('learner_id')!;

    final manager = $$LearnersTableTableManager(
      $_db,
      $_db.learners,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_learnerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$UnitProgressTableFilterComposer
    extends Composer<_$AppDatabase, $UnitProgressTable> {
  $$UnitProgressTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unitId => $composableBuilder(
    column: $table.unitId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastActivityAt => $composableBuilder(
    column: $table.lastActivityAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get masteredAt => $composableBuilder(
    column: $table.masteredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isContentStale => $composableBuilder(
    column: $table.isContentStale,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$LearnersTableFilterComposer get learnerId {
    final $$LearnersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.learnerId,
      referencedTable: $db.learners,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LearnersTableFilterComposer(
            $db: $db,
            $table: $db.learners,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UnitProgressTableOrderingComposer
    extends Composer<_$AppDatabase, $UnitProgressTable> {
  $$UnitProgressTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unitId => $composableBuilder(
    column: $table.unitId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastActivityAt => $composableBuilder(
    column: $table.lastActivityAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get masteredAt => $composableBuilder(
    column: $table.masteredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isContentStale => $composableBuilder(
    column: $table.isContentStale,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$LearnersTableOrderingComposer get learnerId {
    final $$LearnersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.learnerId,
      referencedTable: $db.learners,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LearnersTableOrderingComposer(
            $db: $db,
            $table: $db.learners,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UnitProgressTableAnnotationComposer
    extends Composer<_$AppDatabase, $UnitProgressTable> {
  $$UnitProgressTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get unitId =>
      $composableBuilder(column: $table.unitId, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<DateTime> get lastActivityAt => $composableBuilder(
    column: $table.lastActivityAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get masteredAt => $composableBuilder(
    column: $table.masteredAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isContentStale => $composableBuilder(
    column: $table.isContentStale,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$LearnersTableAnnotationComposer get learnerId {
    final $$LearnersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.learnerId,
      referencedTable: $db.learners,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LearnersTableAnnotationComposer(
            $db: $db,
            $table: $db.learners,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UnitProgressTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UnitProgressTable,
          UnitProgressData,
          $$UnitProgressTableFilterComposer,
          $$UnitProgressTableOrderingComposer,
          $$UnitProgressTableAnnotationComposer,
          $$UnitProgressTableCreateCompanionBuilder,
          $$UnitProgressTableUpdateCompanionBuilder,
          (UnitProgressData, $$UnitProgressTableReferences),
          UnitProgressData,
          PrefetchHooks Function({bool learnerId})
        > {
  $$UnitProgressTableTableManager(_$AppDatabase db, $UnitProgressTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UnitProgressTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UnitProgressTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UnitProgressTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<int> learnerId = const Value.absent(),
                Value<String> unitId = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<DateTime?> lastActivityAt = const Value.absent(),
                Value<DateTime?> masteredAt = const Value.absent(),
                Value<bool> isContentStale = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => UnitProgressCompanion(
                id: id,
                uuid: uuid,
                learnerId: learnerId,
                unitId: unitId,
                state: state,
                lastActivityAt: lastActivityAt,
                masteredAt: masteredAt,
                isContentStale: isContentStale,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String uuid,
                required int learnerId,
                required String unitId,
                required String state,
                Value<DateTime?> lastActivityAt = const Value.absent(),
                Value<DateTime?> masteredAt = const Value.absent(),
                Value<bool> isContentStale = const Value.absent(),
                required DateTime updatedAt,
              }) => UnitProgressCompanion.insert(
                id: id,
                uuid: uuid,
                learnerId: learnerId,
                unitId: unitId,
                state: state,
                lastActivityAt: lastActivityAt,
                masteredAt: masteredAt,
                isContentStale: isContentStale,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$UnitProgressTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({learnerId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (learnerId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.learnerId,
                        referencedTable: $$UnitProgressTableReferences
                            ._learnerIdTable(db),
                        referencedColumn: $$UnitProgressTableReferences
                            ._learnerIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$UnitProgressTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UnitProgressTable,
      UnitProgressData,
      $$UnitProgressTableFilterComposer,
      $$UnitProgressTableOrderingComposer,
      $$UnitProgressTableAnnotationComposer,
      $$UnitProgressTableCreateCompanionBuilder,
      $$UnitProgressTableUpdateCompanionBuilder,
      (UnitProgressData, $$UnitProgressTableReferences),
      UnitProgressData,
      PrefetchHooks Function({bool learnerId})
    >;
typedef $$LessonProgressTableCreateCompanionBuilder =
    LessonProgressCompanion Function({
      Value<int> id,
      required String uuid,
      required int learnerId,
      required String lessonId,
      required String unitId,
      required String state,
      Value<String?> lastActivityId,
      Value<DateTime?> lastPositionUpdatedAt,
      required DateTime updatedAt,
    });
typedef $$LessonProgressTableUpdateCompanionBuilder =
    LessonProgressCompanion Function({
      Value<int> id,
      Value<String> uuid,
      Value<int> learnerId,
      Value<String> lessonId,
      Value<String> unitId,
      Value<String> state,
      Value<String?> lastActivityId,
      Value<DateTime?> lastPositionUpdatedAt,
      Value<DateTime> updatedAt,
    });

final class $$LessonProgressTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $LessonProgressTable,
          LessonProgressData
        > {
  $$LessonProgressTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $LearnersTable _learnerIdTable(_$AppDatabase db) =>
      db.learners.createAlias('lesson_progress__learner_id__learners__id');

  $$LearnersTableProcessedTableManager get learnerId {
    final $_column = $_itemColumn<int>('learner_id')!;

    final manager = $$LearnersTableTableManager(
      $_db,
      $_db.learners,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_learnerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LessonProgressTableFilterComposer
    extends Composer<_$AppDatabase, $LessonProgressTable> {
  $$LessonProgressTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lessonId => $composableBuilder(
    column: $table.lessonId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unitId => $composableBuilder(
    column: $table.unitId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastActivityId => $composableBuilder(
    column: $table.lastActivityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastPositionUpdatedAt => $composableBuilder(
    column: $table.lastPositionUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$LearnersTableFilterComposer get learnerId {
    final $$LearnersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.learnerId,
      referencedTable: $db.learners,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LearnersTableFilterComposer(
            $db: $db,
            $table: $db.learners,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LessonProgressTableOrderingComposer
    extends Composer<_$AppDatabase, $LessonProgressTable> {
  $$LessonProgressTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lessonId => $composableBuilder(
    column: $table.lessonId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unitId => $composableBuilder(
    column: $table.unitId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastActivityId => $composableBuilder(
    column: $table.lastActivityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastPositionUpdatedAt => $composableBuilder(
    column: $table.lastPositionUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$LearnersTableOrderingComposer get learnerId {
    final $$LearnersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.learnerId,
      referencedTable: $db.learners,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LearnersTableOrderingComposer(
            $db: $db,
            $table: $db.learners,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LessonProgressTableAnnotationComposer
    extends Composer<_$AppDatabase, $LessonProgressTable> {
  $$LessonProgressTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get lessonId =>
      $composableBuilder(column: $table.lessonId, builder: (column) => column);

  GeneratedColumn<String> get unitId =>
      $composableBuilder(column: $table.unitId, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<String> get lastActivityId => $composableBuilder(
    column: $table.lastActivityId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastPositionUpdatedAt => $composableBuilder(
    column: $table.lastPositionUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$LearnersTableAnnotationComposer get learnerId {
    final $$LearnersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.learnerId,
      referencedTable: $db.learners,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LearnersTableAnnotationComposer(
            $db: $db,
            $table: $db.learners,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LessonProgressTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LessonProgressTable,
          LessonProgressData,
          $$LessonProgressTableFilterComposer,
          $$LessonProgressTableOrderingComposer,
          $$LessonProgressTableAnnotationComposer,
          $$LessonProgressTableCreateCompanionBuilder,
          $$LessonProgressTableUpdateCompanionBuilder,
          (LessonProgressData, $$LessonProgressTableReferences),
          LessonProgressData,
          PrefetchHooks Function({bool learnerId})
        > {
  $$LessonProgressTableTableManager(
    _$AppDatabase db,
    $LessonProgressTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LessonProgressTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LessonProgressTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LessonProgressTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<int> learnerId = const Value.absent(),
                Value<String> lessonId = const Value.absent(),
                Value<String> unitId = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<String?> lastActivityId = const Value.absent(),
                Value<DateTime?> lastPositionUpdatedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => LessonProgressCompanion(
                id: id,
                uuid: uuid,
                learnerId: learnerId,
                lessonId: lessonId,
                unitId: unitId,
                state: state,
                lastActivityId: lastActivityId,
                lastPositionUpdatedAt: lastPositionUpdatedAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String uuid,
                required int learnerId,
                required String lessonId,
                required String unitId,
                required String state,
                Value<String?> lastActivityId = const Value.absent(),
                Value<DateTime?> lastPositionUpdatedAt = const Value.absent(),
                required DateTime updatedAt,
              }) => LessonProgressCompanion.insert(
                id: id,
                uuid: uuid,
                learnerId: learnerId,
                lessonId: lessonId,
                unitId: unitId,
                state: state,
                lastActivityId: lastActivityId,
                lastPositionUpdatedAt: lastPositionUpdatedAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LessonProgressTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({learnerId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (learnerId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.learnerId,
                        referencedTable: $$LessonProgressTableReferences
                            ._learnerIdTable(db),
                        referencedColumn: $$LessonProgressTableReferences
                            ._learnerIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$LessonProgressTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LessonProgressTable,
      LessonProgressData,
      $$LessonProgressTableFilterComposer,
      $$LessonProgressTableOrderingComposer,
      $$LessonProgressTableAnnotationComposer,
      $$LessonProgressTableCreateCompanionBuilder,
      $$LessonProgressTableUpdateCompanionBuilder,
      (LessonProgressData, $$LessonProgressTableReferences),
      LessonProgressData,
      PrefetchHooks Function({bool learnerId})
    >;
typedef $$ActivityAttemptsTableCreateCompanionBuilder =
    ActivityAttemptsCompanion Function({
      Value<int> id,
      required String uuid,
      required int learnerId,
      required String activityId,
      Value<String?> lessonId,
      required String sessionType,
      Value<String?> sessionId,
      required String mode,
      required String evidenceSkill,
      Value<String?> rawAnswer,
      Value<bool?> isCorrect,
      Value<double?> score,
      Value<String?> criteriaScores,
      Value<bool> wasFallback,
      required DateTime attemptedAt,
      required DateTime updatedAt,
    });
typedef $$ActivityAttemptsTableUpdateCompanionBuilder =
    ActivityAttemptsCompanion Function({
      Value<int> id,
      Value<String> uuid,
      Value<int> learnerId,
      Value<String> activityId,
      Value<String?> lessonId,
      Value<String> sessionType,
      Value<String?> sessionId,
      Value<String> mode,
      Value<String> evidenceSkill,
      Value<String?> rawAnswer,
      Value<bool?> isCorrect,
      Value<double?> score,
      Value<String?> criteriaScores,
      Value<bool> wasFallback,
      Value<DateTime> attemptedAt,
      Value<DateTime> updatedAt,
    });

final class $$ActivityAttemptsTableReferences
    extends
        BaseReferences<_$AppDatabase, $ActivityAttemptsTable, ActivityAttempt> {
  $$ActivityAttemptsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $LearnersTable _learnerIdTable(_$AppDatabase db) =>
      db.learners.createAlias('activity_attempts__learner_id__learners__id');

  $$LearnersTableProcessedTableManager get learnerId {
    final $_column = $_itemColumn<int>('learner_id')!;

    final manager = $$LearnersTableTableManager(
      $_db,
      $_db.learners,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_learnerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $ActivityAttemptCanDosTable,
    List<ActivityAttemptCanDo>
  >
  _activityAttemptCanDosRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.activityAttemptCanDos,
        aliasName:
            'activity_attempts__id__activity_attempt_can_dos__attempt_id',
      );

  $$ActivityAttemptCanDosTableProcessedTableManager
  get activityAttemptCanDosRefs {
    final manager = $$ActivityAttemptCanDosTableTableManager(
      $_db,
      $_db.activityAttemptCanDos,
    ).filter((f) => f.attemptId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _activityAttemptCanDosRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ActivityAttemptsTableFilterComposer
    extends Composer<_$AppDatabase, $ActivityAttemptsTable> {
  $$ActivityAttemptsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get activityId => $composableBuilder(
    column: $table.activityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lessonId => $composableBuilder(
    column: $table.lessonId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionType => $composableBuilder(
    column: $table.sessionType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get evidenceSkill => $composableBuilder(
    column: $table.evidenceSkill,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawAnswer => $composableBuilder(
    column: $table.rawAnswer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCorrect => $composableBuilder(
    column: $table.isCorrect,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get criteriaScores => $composableBuilder(
    column: $table.criteriaScores,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get wasFallback => $composableBuilder(
    column: $table.wasFallback,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get attemptedAt => $composableBuilder(
    column: $table.attemptedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$LearnersTableFilterComposer get learnerId {
    final $$LearnersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.learnerId,
      referencedTable: $db.learners,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LearnersTableFilterComposer(
            $db: $db,
            $table: $db.learners,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> activityAttemptCanDosRefs(
    Expression<bool> Function($$ActivityAttemptCanDosTableFilterComposer f) f,
  ) {
    final $$ActivityAttemptCanDosTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.activityAttemptCanDos,
          getReferencedColumn: (t) => t.attemptId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ActivityAttemptCanDosTableFilterComposer(
                $db: $db,
                $table: $db.activityAttemptCanDos,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ActivityAttemptsTableOrderingComposer
    extends Composer<_$AppDatabase, $ActivityAttemptsTable> {
  $$ActivityAttemptsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get activityId => $composableBuilder(
    column: $table.activityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lessonId => $composableBuilder(
    column: $table.lessonId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionType => $composableBuilder(
    column: $table.sessionType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get evidenceSkill => $composableBuilder(
    column: $table.evidenceSkill,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawAnswer => $composableBuilder(
    column: $table.rawAnswer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCorrect => $composableBuilder(
    column: $table.isCorrect,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get criteriaScores => $composableBuilder(
    column: $table.criteriaScores,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get wasFallback => $composableBuilder(
    column: $table.wasFallback,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get attemptedAt => $composableBuilder(
    column: $table.attemptedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$LearnersTableOrderingComposer get learnerId {
    final $$LearnersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.learnerId,
      referencedTable: $db.learners,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LearnersTableOrderingComposer(
            $db: $db,
            $table: $db.learners,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ActivityAttemptsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ActivityAttemptsTable> {
  $$ActivityAttemptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get activityId => $composableBuilder(
    column: $table.activityId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lessonId =>
      $composableBuilder(column: $table.lessonId, builder: (column) => column);

  GeneratedColumn<String> get sessionType => $composableBuilder(
    column: $table.sessionType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumn<String> get evidenceSkill => $composableBuilder(
    column: $table.evidenceSkill,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rawAnswer =>
      $composableBuilder(column: $table.rawAnswer, builder: (column) => column);

  GeneratedColumn<bool> get isCorrect =>
      $composableBuilder(column: $table.isCorrect, builder: (column) => column);

  GeneratedColumn<double> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);

  GeneratedColumn<String> get criteriaScores => $composableBuilder(
    column: $table.criteriaScores,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get wasFallback => $composableBuilder(
    column: $table.wasFallback,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get attemptedAt => $composableBuilder(
    column: $table.attemptedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$LearnersTableAnnotationComposer get learnerId {
    final $$LearnersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.learnerId,
      referencedTable: $db.learners,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LearnersTableAnnotationComposer(
            $db: $db,
            $table: $db.learners,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> activityAttemptCanDosRefs<T extends Object>(
    Expression<T> Function($$ActivityAttemptCanDosTableAnnotationComposer a) f,
  ) {
    final $$ActivityAttemptCanDosTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.activityAttemptCanDos,
          getReferencedColumn: (t) => t.attemptId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ActivityAttemptCanDosTableAnnotationComposer(
                $db: $db,
                $table: $db.activityAttemptCanDos,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ActivityAttemptsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ActivityAttemptsTable,
          ActivityAttempt,
          $$ActivityAttemptsTableFilterComposer,
          $$ActivityAttemptsTableOrderingComposer,
          $$ActivityAttemptsTableAnnotationComposer,
          $$ActivityAttemptsTableCreateCompanionBuilder,
          $$ActivityAttemptsTableUpdateCompanionBuilder,
          (ActivityAttempt, $$ActivityAttemptsTableReferences),
          ActivityAttempt,
          PrefetchHooks Function({
            bool learnerId,
            bool activityAttemptCanDosRefs,
          })
        > {
  $$ActivityAttemptsTableTableManager(
    _$AppDatabase db,
    $ActivityAttemptsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ActivityAttemptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ActivityAttemptsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ActivityAttemptsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<int> learnerId = const Value.absent(),
                Value<String> activityId = const Value.absent(),
                Value<String?> lessonId = const Value.absent(),
                Value<String> sessionType = const Value.absent(),
                Value<String?> sessionId = const Value.absent(),
                Value<String> mode = const Value.absent(),
                Value<String> evidenceSkill = const Value.absent(),
                Value<String?> rawAnswer = const Value.absent(),
                Value<bool?> isCorrect = const Value.absent(),
                Value<double?> score = const Value.absent(),
                Value<String?> criteriaScores = const Value.absent(),
                Value<bool> wasFallback = const Value.absent(),
                Value<DateTime> attemptedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => ActivityAttemptsCompanion(
                id: id,
                uuid: uuid,
                learnerId: learnerId,
                activityId: activityId,
                lessonId: lessonId,
                sessionType: sessionType,
                sessionId: sessionId,
                mode: mode,
                evidenceSkill: evidenceSkill,
                rawAnswer: rawAnswer,
                isCorrect: isCorrect,
                score: score,
                criteriaScores: criteriaScores,
                wasFallback: wasFallback,
                attemptedAt: attemptedAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String uuid,
                required int learnerId,
                required String activityId,
                Value<String?> lessonId = const Value.absent(),
                required String sessionType,
                Value<String?> sessionId = const Value.absent(),
                required String mode,
                required String evidenceSkill,
                Value<String?> rawAnswer = const Value.absent(),
                Value<bool?> isCorrect = const Value.absent(),
                Value<double?> score = const Value.absent(),
                Value<String?> criteriaScores = const Value.absent(),
                Value<bool> wasFallback = const Value.absent(),
                required DateTime attemptedAt,
                required DateTime updatedAt,
              }) => ActivityAttemptsCompanion.insert(
                id: id,
                uuid: uuid,
                learnerId: learnerId,
                activityId: activityId,
                lessonId: lessonId,
                sessionType: sessionType,
                sessionId: sessionId,
                mode: mode,
                evidenceSkill: evidenceSkill,
                rawAnswer: rawAnswer,
                isCorrect: isCorrect,
                score: score,
                criteriaScores: criteriaScores,
                wasFallback: wasFallback,
                attemptedAt: attemptedAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ActivityAttemptsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({learnerId = false, activityAttemptCanDosRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (activityAttemptCanDosRefs) db.activityAttemptCanDos,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (learnerId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.learnerId,
                            referencedTable: $$ActivityAttemptsTableReferences
                                ._learnerIdTable(db),
                            referencedColumn: $$ActivityAttemptsTableReferences
                                ._learnerIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (activityAttemptCanDosRefs)
                        await $_getPrefetchedData<
                          ActivityAttempt,
                          $ActivityAttemptsTable,
                          ActivityAttemptCanDo
                        >(
                          currentTable: table,
                          referencedTable: $$ActivityAttemptsTableReferences
                              ._activityAttemptCanDosRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ActivityAttemptsTableReferences(
                                db,
                                table,
                                p0,
                              ).activityAttemptCanDosRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.attemptId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ActivityAttemptsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ActivityAttemptsTable,
      ActivityAttempt,
      $$ActivityAttemptsTableFilterComposer,
      $$ActivityAttemptsTableOrderingComposer,
      $$ActivityAttemptsTableAnnotationComposer,
      $$ActivityAttemptsTableCreateCompanionBuilder,
      $$ActivityAttemptsTableUpdateCompanionBuilder,
      (ActivityAttempt, $$ActivityAttemptsTableReferences),
      ActivityAttempt,
      PrefetchHooks Function({bool learnerId, bool activityAttemptCanDosRefs})
    >;
typedef $$ActivityAttemptCanDosTableCreateCompanionBuilder =
    ActivityAttemptCanDosCompanion Function({
      Value<int> id,
      required int attemptId,
      required String canDoId,
    });
typedef $$ActivityAttemptCanDosTableUpdateCompanionBuilder =
    ActivityAttemptCanDosCompanion Function({
      Value<int> id,
      Value<int> attemptId,
      Value<String> canDoId,
    });

final class $$ActivityAttemptCanDosTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ActivityAttemptCanDosTable,
          ActivityAttemptCanDo
        > {
  $$ActivityAttemptCanDosTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ActivityAttemptsTable _attemptIdTable(_$AppDatabase db) =>
      db.activityAttempts.createAlias(
        'activity_attempt_can_dos__attempt_id__activity_attempts__id',
      );

  $$ActivityAttemptsTableProcessedTableManager get attemptId {
    final $_column = $_itemColumn<int>('attempt_id')!;

    final manager = $$ActivityAttemptsTableTableManager(
      $_db,
      $_db.activityAttempts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_attemptIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ActivityAttemptCanDosTableFilterComposer
    extends Composer<_$AppDatabase, $ActivityAttemptCanDosTable> {
  $$ActivityAttemptCanDosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get canDoId => $composableBuilder(
    column: $table.canDoId,
    builder: (column) => ColumnFilters(column),
  );

  $$ActivityAttemptsTableFilterComposer get attemptId {
    final $$ActivityAttemptsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.attemptId,
      referencedTable: $db.activityAttempts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ActivityAttemptsTableFilterComposer(
            $db: $db,
            $table: $db.activityAttempts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ActivityAttemptCanDosTableOrderingComposer
    extends Composer<_$AppDatabase, $ActivityAttemptCanDosTable> {
  $$ActivityAttemptCanDosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get canDoId => $composableBuilder(
    column: $table.canDoId,
    builder: (column) => ColumnOrderings(column),
  );

  $$ActivityAttemptsTableOrderingComposer get attemptId {
    final $$ActivityAttemptsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.attemptId,
      referencedTable: $db.activityAttempts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ActivityAttemptsTableOrderingComposer(
            $db: $db,
            $table: $db.activityAttempts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ActivityAttemptCanDosTableAnnotationComposer
    extends Composer<_$AppDatabase, $ActivityAttemptCanDosTable> {
  $$ActivityAttemptCanDosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get canDoId =>
      $composableBuilder(column: $table.canDoId, builder: (column) => column);

  $$ActivityAttemptsTableAnnotationComposer get attemptId {
    final $$ActivityAttemptsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.attemptId,
      referencedTable: $db.activityAttempts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ActivityAttemptsTableAnnotationComposer(
            $db: $db,
            $table: $db.activityAttempts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ActivityAttemptCanDosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ActivityAttemptCanDosTable,
          ActivityAttemptCanDo,
          $$ActivityAttemptCanDosTableFilterComposer,
          $$ActivityAttemptCanDosTableOrderingComposer,
          $$ActivityAttemptCanDosTableAnnotationComposer,
          $$ActivityAttemptCanDosTableCreateCompanionBuilder,
          $$ActivityAttemptCanDosTableUpdateCompanionBuilder,
          (ActivityAttemptCanDo, $$ActivityAttemptCanDosTableReferences),
          ActivityAttemptCanDo,
          PrefetchHooks Function({bool attemptId})
        > {
  $$ActivityAttemptCanDosTableTableManager(
    _$AppDatabase db,
    $ActivityAttemptCanDosTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ActivityAttemptCanDosTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$ActivityAttemptCanDosTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ActivityAttemptCanDosTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> attemptId = const Value.absent(),
                Value<String> canDoId = const Value.absent(),
              }) => ActivityAttemptCanDosCompanion(
                id: id,
                attemptId: attemptId,
                canDoId: canDoId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int attemptId,
                required String canDoId,
              }) => ActivityAttemptCanDosCompanion.insert(
                id: id,
                attemptId: attemptId,
                canDoId: canDoId,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ActivityAttemptCanDosTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({attemptId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (attemptId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.attemptId,
                        referencedTable: $$ActivityAttemptCanDosTableReferences
                            ._attemptIdTable(db),
                        referencedColumn: $$ActivityAttemptCanDosTableReferences
                            ._attemptIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ActivityAttemptCanDosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ActivityAttemptCanDosTable,
      ActivityAttemptCanDo,
      $$ActivityAttemptCanDosTableFilterComposer,
      $$ActivityAttemptCanDosTableOrderingComposer,
      $$ActivityAttemptCanDosTableAnnotationComposer,
      $$ActivityAttemptCanDosTableCreateCompanionBuilder,
      $$ActivityAttemptCanDosTableUpdateCompanionBuilder,
      (ActivityAttemptCanDo, $$ActivityAttemptCanDosTableReferences),
      ActivityAttemptCanDo,
      PrefetchHooks Function({bool attemptId})
    >;
typedef $$PlacementAttemptsTableCreateCompanionBuilder =
    PlacementAttemptsCompanion Function({
      Value<int> id,
      required String uuid,
      required int learnerId,
      required DateTime startedAt,
      Value<DateTime?> completedAt,
      Value<int> stageReached,
      Value<String?> outcome,
      Value<String?> recommendedUnitId,
      Value<String?> confidenceSelfReports,
      Value<String?> itemSamplingSeed,
    });
typedef $$PlacementAttemptsTableUpdateCompanionBuilder =
    PlacementAttemptsCompanion Function({
      Value<int> id,
      Value<String> uuid,
      Value<int> learnerId,
      Value<DateTime> startedAt,
      Value<DateTime?> completedAt,
      Value<int> stageReached,
      Value<String?> outcome,
      Value<String?> recommendedUnitId,
      Value<String?> confidenceSelfReports,
      Value<String?> itemSamplingSeed,
    });

final class $$PlacementAttemptsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $PlacementAttemptsTable,
          PlacementAttempt
        > {
  $$PlacementAttemptsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $LearnersTable _learnerIdTable(_$AppDatabase db) =>
      db.learners.createAlias('placement_attempts__learner_id__learners__id');

  $$LearnersTableProcessedTableManager get learnerId {
    final $_column = $_itemColumn<int>('learner_id')!;

    final manager = $$LearnersTableTableManager(
      $_db,
      $_db.learners,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_learnerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PlacementAttemptsTableFilterComposer
    extends Composer<_$AppDatabase, $PlacementAttemptsTable> {
  $$PlacementAttemptsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stageReached => $composableBuilder(
    column: $table.stageReached,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get outcome => $composableBuilder(
    column: $table.outcome,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recommendedUnitId => $composableBuilder(
    column: $table.recommendedUnitId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get confidenceSelfReports => $composableBuilder(
    column: $table.confidenceSelfReports,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemSamplingSeed => $composableBuilder(
    column: $table.itemSamplingSeed,
    builder: (column) => ColumnFilters(column),
  );

  $$LearnersTableFilterComposer get learnerId {
    final $$LearnersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.learnerId,
      referencedTable: $db.learners,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LearnersTableFilterComposer(
            $db: $db,
            $table: $db.learners,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlacementAttemptsTableOrderingComposer
    extends Composer<_$AppDatabase, $PlacementAttemptsTable> {
  $$PlacementAttemptsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stageReached => $composableBuilder(
    column: $table.stageReached,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get outcome => $composableBuilder(
    column: $table.outcome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recommendedUnitId => $composableBuilder(
    column: $table.recommendedUnitId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get confidenceSelfReports => $composableBuilder(
    column: $table.confidenceSelfReports,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemSamplingSeed => $composableBuilder(
    column: $table.itemSamplingSeed,
    builder: (column) => ColumnOrderings(column),
  );

  $$LearnersTableOrderingComposer get learnerId {
    final $$LearnersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.learnerId,
      referencedTable: $db.learners,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LearnersTableOrderingComposer(
            $db: $db,
            $table: $db.learners,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlacementAttemptsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlacementAttemptsTable> {
  $$PlacementAttemptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get stageReached => $composableBuilder(
    column: $table.stageReached,
    builder: (column) => column,
  );

  GeneratedColumn<String> get outcome =>
      $composableBuilder(column: $table.outcome, builder: (column) => column);

  GeneratedColumn<String> get recommendedUnitId => $composableBuilder(
    column: $table.recommendedUnitId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get confidenceSelfReports => $composableBuilder(
    column: $table.confidenceSelfReports,
    builder: (column) => column,
  );

  GeneratedColumn<String> get itemSamplingSeed => $composableBuilder(
    column: $table.itemSamplingSeed,
    builder: (column) => column,
  );

  $$LearnersTableAnnotationComposer get learnerId {
    final $$LearnersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.learnerId,
      referencedTable: $db.learners,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LearnersTableAnnotationComposer(
            $db: $db,
            $table: $db.learners,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlacementAttemptsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlacementAttemptsTable,
          PlacementAttempt,
          $$PlacementAttemptsTableFilterComposer,
          $$PlacementAttemptsTableOrderingComposer,
          $$PlacementAttemptsTableAnnotationComposer,
          $$PlacementAttemptsTableCreateCompanionBuilder,
          $$PlacementAttemptsTableUpdateCompanionBuilder,
          (PlacementAttempt, $$PlacementAttemptsTableReferences),
          PlacementAttempt,
          PrefetchHooks Function({bool learnerId})
        > {
  $$PlacementAttemptsTableTableManager(
    _$AppDatabase db,
    $PlacementAttemptsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlacementAttemptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlacementAttemptsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlacementAttemptsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<int> learnerId = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<int> stageReached = const Value.absent(),
                Value<String?> outcome = const Value.absent(),
                Value<String?> recommendedUnitId = const Value.absent(),
                Value<String?> confidenceSelfReports = const Value.absent(),
                Value<String?> itemSamplingSeed = const Value.absent(),
              }) => PlacementAttemptsCompanion(
                id: id,
                uuid: uuid,
                learnerId: learnerId,
                startedAt: startedAt,
                completedAt: completedAt,
                stageReached: stageReached,
                outcome: outcome,
                recommendedUnitId: recommendedUnitId,
                confidenceSelfReports: confidenceSelfReports,
                itemSamplingSeed: itemSamplingSeed,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String uuid,
                required int learnerId,
                required DateTime startedAt,
                Value<DateTime?> completedAt = const Value.absent(),
                Value<int> stageReached = const Value.absent(),
                Value<String?> outcome = const Value.absent(),
                Value<String?> recommendedUnitId = const Value.absent(),
                Value<String?> confidenceSelfReports = const Value.absent(),
                Value<String?> itemSamplingSeed = const Value.absent(),
              }) => PlacementAttemptsCompanion.insert(
                id: id,
                uuid: uuid,
                learnerId: learnerId,
                startedAt: startedAt,
                completedAt: completedAt,
                stageReached: stageReached,
                outcome: outcome,
                recommendedUnitId: recommendedUnitId,
                confidenceSelfReports: confidenceSelfReports,
                itemSamplingSeed: itemSamplingSeed,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PlacementAttemptsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({learnerId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (learnerId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.learnerId,
                        referencedTable: $$PlacementAttemptsTableReferences
                            ._learnerIdTable(db),
                        referencedColumn: $$PlacementAttemptsTableReferences
                            ._learnerIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PlacementAttemptsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlacementAttemptsTable,
      PlacementAttempt,
      $$PlacementAttemptsTableFilterComposer,
      $$PlacementAttemptsTableOrderingComposer,
      $$PlacementAttemptsTableAnnotationComposer,
      $$PlacementAttemptsTableCreateCompanionBuilder,
      $$PlacementAttemptsTableUpdateCompanionBuilder,
      (PlacementAttempt, $$PlacementAttemptsTableReferences),
      PlacementAttempt,
      PrefetchHooks Function({bool learnerId})
    >;
typedef $$FinalMissionAttemptsTableCreateCompanionBuilder =
    FinalMissionAttemptsCompanion Function({
      Value<int> id,
      required String uuid,
      required int learnerId,
      required String courseId,
      required DateTime startedAt,
      Value<DateTime?> completedAt,
      Value<String?> stagesCompleted,
      Value<String?> outcome,
    });
typedef $$FinalMissionAttemptsTableUpdateCompanionBuilder =
    FinalMissionAttemptsCompanion Function({
      Value<int> id,
      Value<String> uuid,
      Value<int> learnerId,
      Value<String> courseId,
      Value<DateTime> startedAt,
      Value<DateTime?> completedAt,
      Value<String?> stagesCompleted,
      Value<String?> outcome,
    });

final class $$FinalMissionAttemptsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $FinalMissionAttemptsTable,
          FinalMissionAttempt
        > {
  $$FinalMissionAttemptsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $LearnersTable _learnerIdTable(_$AppDatabase db) => db.learners
      .createAlias('final_mission_attempts__learner_id__learners__id');

  $$LearnersTableProcessedTableManager get learnerId {
    final $_column = $_itemColumn<int>('learner_id')!;

    final manager = $$LearnersTableTableManager(
      $_db,
      $_db.learners,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_learnerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$FinalMissionAttemptsTableFilterComposer
    extends Composer<_$AppDatabase, $FinalMissionAttemptsTable> {
  $$FinalMissionAttemptsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get courseId => $composableBuilder(
    column: $table.courseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stagesCompleted => $composableBuilder(
    column: $table.stagesCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get outcome => $composableBuilder(
    column: $table.outcome,
    builder: (column) => ColumnFilters(column),
  );

  $$LearnersTableFilterComposer get learnerId {
    final $$LearnersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.learnerId,
      referencedTable: $db.learners,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LearnersTableFilterComposer(
            $db: $db,
            $table: $db.learners,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FinalMissionAttemptsTableOrderingComposer
    extends Composer<_$AppDatabase, $FinalMissionAttemptsTable> {
  $$FinalMissionAttemptsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get courseId => $composableBuilder(
    column: $table.courseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stagesCompleted => $composableBuilder(
    column: $table.stagesCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get outcome => $composableBuilder(
    column: $table.outcome,
    builder: (column) => ColumnOrderings(column),
  );

  $$LearnersTableOrderingComposer get learnerId {
    final $$LearnersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.learnerId,
      referencedTable: $db.learners,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LearnersTableOrderingComposer(
            $db: $db,
            $table: $db.learners,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FinalMissionAttemptsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FinalMissionAttemptsTable> {
  $$FinalMissionAttemptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get courseId =>
      $composableBuilder(column: $table.courseId, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get stagesCompleted => $composableBuilder(
    column: $table.stagesCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<String> get outcome =>
      $composableBuilder(column: $table.outcome, builder: (column) => column);

  $$LearnersTableAnnotationComposer get learnerId {
    final $$LearnersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.learnerId,
      referencedTable: $db.learners,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LearnersTableAnnotationComposer(
            $db: $db,
            $table: $db.learners,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FinalMissionAttemptsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FinalMissionAttemptsTable,
          FinalMissionAttempt,
          $$FinalMissionAttemptsTableFilterComposer,
          $$FinalMissionAttemptsTableOrderingComposer,
          $$FinalMissionAttemptsTableAnnotationComposer,
          $$FinalMissionAttemptsTableCreateCompanionBuilder,
          $$FinalMissionAttemptsTableUpdateCompanionBuilder,
          (FinalMissionAttempt, $$FinalMissionAttemptsTableReferences),
          FinalMissionAttempt,
          PrefetchHooks Function({bool learnerId})
        > {
  $$FinalMissionAttemptsTableTableManager(
    _$AppDatabase db,
    $FinalMissionAttemptsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FinalMissionAttemptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FinalMissionAttemptsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$FinalMissionAttemptsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<int> learnerId = const Value.absent(),
                Value<String> courseId = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<String?> stagesCompleted = const Value.absent(),
                Value<String?> outcome = const Value.absent(),
              }) => FinalMissionAttemptsCompanion(
                id: id,
                uuid: uuid,
                learnerId: learnerId,
                courseId: courseId,
                startedAt: startedAt,
                completedAt: completedAt,
                stagesCompleted: stagesCompleted,
                outcome: outcome,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String uuid,
                required int learnerId,
                required String courseId,
                required DateTime startedAt,
                Value<DateTime?> completedAt = const Value.absent(),
                Value<String?> stagesCompleted = const Value.absent(),
                Value<String?> outcome = const Value.absent(),
              }) => FinalMissionAttemptsCompanion.insert(
                id: id,
                uuid: uuid,
                learnerId: learnerId,
                courseId: courseId,
                startedAt: startedAt,
                completedAt: completedAt,
                stagesCompleted: stagesCompleted,
                outcome: outcome,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$FinalMissionAttemptsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({learnerId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (learnerId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.learnerId,
                        referencedTable: $$FinalMissionAttemptsTableReferences
                            ._learnerIdTable(db),
                        referencedColumn: $$FinalMissionAttemptsTableReferences
                            ._learnerIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$FinalMissionAttemptsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FinalMissionAttemptsTable,
      FinalMissionAttempt,
      $$FinalMissionAttemptsTableFilterComposer,
      $$FinalMissionAttemptsTableOrderingComposer,
      $$FinalMissionAttemptsTableAnnotationComposer,
      $$FinalMissionAttemptsTableCreateCompanionBuilder,
      $$FinalMissionAttemptsTableUpdateCompanionBuilder,
      (FinalMissionAttempt, $$FinalMissionAttemptsTableReferences),
      FinalMissionAttempt,
      PrefetchHooks Function({bool learnerId})
    >;
typedef $$FinalAssessmentAttemptsTableCreateCompanionBuilder =
    FinalAssessmentAttemptsCompanion Function({
      Value<int> id,
      required String uuid,
      required int learnerId,
      required String courseId,
      required DateTime startedAt,
      Value<DateTime?> completedAt,
      Value<String?> sectionResults,
      Value<String?> outcomeSummary,
    });
typedef $$FinalAssessmentAttemptsTableUpdateCompanionBuilder =
    FinalAssessmentAttemptsCompanion Function({
      Value<int> id,
      Value<String> uuid,
      Value<int> learnerId,
      Value<String> courseId,
      Value<DateTime> startedAt,
      Value<DateTime?> completedAt,
      Value<String?> sectionResults,
      Value<String?> outcomeSummary,
    });

final class $$FinalAssessmentAttemptsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $FinalAssessmentAttemptsTable,
          FinalAssessmentAttempt
        > {
  $$FinalAssessmentAttemptsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $LearnersTable _learnerIdTable(_$AppDatabase db) => db.learners
      .createAlias('final_assessment_attempts__learner_id__learners__id');

  $$LearnersTableProcessedTableManager get learnerId {
    final $_column = $_itemColumn<int>('learner_id')!;

    final manager = $$LearnersTableTableManager(
      $_db,
      $_db.learners,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_learnerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$FinalAssessmentAttemptsTableFilterComposer
    extends Composer<_$AppDatabase, $FinalAssessmentAttemptsTable> {
  $$FinalAssessmentAttemptsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get courseId => $composableBuilder(
    column: $table.courseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sectionResults => $composableBuilder(
    column: $table.sectionResults,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get outcomeSummary => $composableBuilder(
    column: $table.outcomeSummary,
    builder: (column) => ColumnFilters(column),
  );

  $$LearnersTableFilterComposer get learnerId {
    final $$LearnersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.learnerId,
      referencedTable: $db.learners,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LearnersTableFilterComposer(
            $db: $db,
            $table: $db.learners,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FinalAssessmentAttemptsTableOrderingComposer
    extends Composer<_$AppDatabase, $FinalAssessmentAttemptsTable> {
  $$FinalAssessmentAttemptsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get courseId => $composableBuilder(
    column: $table.courseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sectionResults => $composableBuilder(
    column: $table.sectionResults,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get outcomeSummary => $composableBuilder(
    column: $table.outcomeSummary,
    builder: (column) => ColumnOrderings(column),
  );

  $$LearnersTableOrderingComposer get learnerId {
    final $$LearnersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.learnerId,
      referencedTable: $db.learners,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LearnersTableOrderingComposer(
            $db: $db,
            $table: $db.learners,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FinalAssessmentAttemptsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FinalAssessmentAttemptsTable> {
  $$FinalAssessmentAttemptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get courseId =>
      $composableBuilder(column: $table.courseId, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sectionResults => $composableBuilder(
    column: $table.sectionResults,
    builder: (column) => column,
  );

  GeneratedColumn<String> get outcomeSummary => $composableBuilder(
    column: $table.outcomeSummary,
    builder: (column) => column,
  );

  $$LearnersTableAnnotationComposer get learnerId {
    final $$LearnersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.learnerId,
      referencedTable: $db.learners,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LearnersTableAnnotationComposer(
            $db: $db,
            $table: $db.learners,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FinalAssessmentAttemptsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FinalAssessmentAttemptsTable,
          FinalAssessmentAttempt,
          $$FinalAssessmentAttemptsTableFilterComposer,
          $$FinalAssessmentAttemptsTableOrderingComposer,
          $$FinalAssessmentAttemptsTableAnnotationComposer,
          $$FinalAssessmentAttemptsTableCreateCompanionBuilder,
          $$FinalAssessmentAttemptsTableUpdateCompanionBuilder,
          (FinalAssessmentAttempt, $$FinalAssessmentAttemptsTableReferences),
          FinalAssessmentAttempt,
          PrefetchHooks Function({bool learnerId})
        > {
  $$FinalAssessmentAttemptsTableTableManager(
    _$AppDatabase db,
    $FinalAssessmentAttemptsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FinalAssessmentAttemptsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$FinalAssessmentAttemptsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$FinalAssessmentAttemptsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<int> learnerId = const Value.absent(),
                Value<String> courseId = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<String?> sectionResults = const Value.absent(),
                Value<String?> outcomeSummary = const Value.absent(),
              }) => FinalAssessmentAttemptsCompanion(
                id: id,
                uuid: uuid,
                learnerId: learnerId,
                courseId: courseId,
                startedAt: startedAt,
                completedAt: completedAt,
                sectionResults: sectionResults,
                outcomeSummary: outcomeSummary,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String uuid,
                required int learnerId,
                required String courseId,
                required DateTime startedAt,
                Value<DateTime?> completedAt = const Value.absent(),
                Value<String?> sectionResults = const Value.absent(),
                Value<String?> outcomeSummary = const Value.absent(),
              }) => FinalAssessmentAttemptsCompanion.insert(
                id: id,
                uuid: uuid,
                learnerId: learnerId,
                courseId: courseId,
                startedAt: startedAt,
                completedAt: completedAt,
                sectionResults: sectionResults,
                outcomeSummary: outcomeSummary,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$FinalAssessmentAttemptsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({learnerId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (learnerId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.learnerId,
                        referencedTable:
                            $$FinalAssessmentAttemptsTableReferences
                                ._learnerIdTable(db),
                        referencedColumn:
                            $$FinalAssessmentAttemptsTableReferences
                                ._learnerIdTable(db)
                                .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$FinalAssessmentAttemptsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FinalAssessmentAttemptsTable,
      FinalAssessmentAttempt,
      $$FinalAssessmentAttemptsTableFilterComposer,
      $$FinalAssessmentAttemptsTableOrderingComposer,
      $$FinalAssessmentAttemptsTableAnnotationComposer,
      $$FinalAssessmentAttemptsTableCreateCompanionBuilder,
      $$FinalAssessmentAttemptsTableUpdateCompanionBuilder,
      (FinalAssessmentAttempt, $$FinalAssessmentAttemptsTableReferences),
      FinalAssessmentAttempt,
      PrefetchHooks Function({bool learnerId})
    >;
typedef $$VocabularyReviewStateTableCreateCompanionBuilder =
    VocabularyReviewStateCompanion Function({
      Value<int> id,
      required String uuid,
      required int learnerId,
      Value<String?> lexiconId,
      Value<String?> chunkId,
      Value<bool> isFavorite,
      Value<String?> confidenceMarker,
      Value<double> easeFactor,
      Value<int> intervalDays,
      Value<int> repetitions,
      Value<DateTime?> dueAt,
      Value<DateTime?> lastReviewedAt,
      required DateTime updatedAt,
    });
typedef $$VocabularyReviewStateTableUpdateCompanionBuilder =
    VocabularyReviewStateCompanion Function({
      Value<int> id,
      Value<String> uuid,
      Value<int> learnerId,
      Value<String?> lexiconId,
      Value<String?> chunkId,
      Value<bool> isFavorite,
      Value<String?> confidenceMarker,
      Value<double> easeFactor,
      Value<int> intervalDays,
      Value<int> repetitions,
      Value<DateTime?> dueAt,
      Value<DateTime?> lastReviewedAt,
      Value<DateTime> updatedAt,
    });

final class $$VocabularyReviewStateTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $VocabularyReviewStateTable,
          VocabularyReviewStateData
        > {
  $$VocabularyReviewStateTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $LearnersTable _learnerIdTable(_$AppDatabase db) => db.learners
      .createAlias('vocabulary_review_state__learner_id__learners__id');

  $$LearnersTableProcessedTableManager get learnerId {
    final $_column = $_itemColumn<int>('learner_id')!;

    final manager = $$LearnersTableTableManager(
      $_db,
      $_db.learners,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_learnerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$VocabularyReviewStateTableFilterComposer
    extends Composer<_$AppDatabase, $VocabularyReviewStateTable> {
  $$VocabularyReviewStateTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lexiconId => $composableBuilder(
    column: $table.lexiconId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get chunkId => $composableBuilder(
    column: $table.chunkId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get confidenceMarker => $composableBuilder(
    column: $table.confidenceMarker,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get easeFactor => $composableBuilder(
    column: $table.easeFactor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get repetitions => $composableBuilder(
    column: $table.repetitions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastReviewedAt => $composableBuilder(
    column: $table.lastReviewedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$LearnersTableFilterComposer get learnerId {
    final $$LearnersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.learnerId,
      referencedTable: $db.learners,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LearnersTableFilterComposer(
            $db: $db,
            $table: $db.learners,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VocabularyReviewStateTableOrderingComposer
    extends Composer<_$AppDatabase, $VocabularyReviewStateTable> {
  $$VocabularyReviewStateTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lexiconId => $composableBuilder(
    column: $table.lexiconId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get chunkId => $composableBuilder(
    column: $table.chunkId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get confidenceMarker => $composableBuilder(
    column: $table.confidenceMarker,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get easeFactor => $composableBuilder(
    column: $table.easeFactor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get repetitions => $composableBuilder(
    column: $table.repetitions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastReviewedAt => $composableBuilder(
    column: $table.lastReviewedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$LearnersTableOrderingComposer get learnerId {
    final $$LearnersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.learnerId,
      referencedTable: $db.learners,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LearnersTableOrderingComposer(
            $db: $db,
            $table: $db.learners,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VocabularyReviewStateTableAnnotationComposer
    extends Composer<_$AppDatabase, $VocabularyReviewStateTable> {
  $$VocabularyReviewStateTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get lexiconId =>
      $composableBuilder(column: $table.lexiconId, builder: (column) => column);

  GeneratedColumn<String> get chunkId =>
      $composableBuilder(column: $table.chunkId, builder: (column) => column);

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => column,
  );

  GeneratedColumn<String> get confidenceMarker => $composableBuilder(
    column: $table.confidenceMarker,
    builder: (column) => column,
  );

  GeneratedColumn<double> get easeFactor => $composableBuilder(
    column: $table.easeFactor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => column,
  );

  GeneratedColumn<int> get repetitions => $composableBuilder(
    column: $table.repetitions,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get dueAt =>
      $composableBuilder(column: $table.dueAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastReviewedAt => $composableBuilder(
    column: $table.lastReviewedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$LearnersTableAnnotationComposer get learnerId {
    final $$LearnersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.learnerId,
      referencedTable: $db.learners,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LearnersTableAnnotationComposer(
            $db: $db,
            $table: $db.learners,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VocabularyReviewStateTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VocabularyReviewStateTable,
          VocabularyReviewStateData,
          $$VocabularyReviewStateTableFilterComposer,
          $$VocabularyReviewStateTableOrderingComposer,
          $$VocabularyReviewStateTableAnnotationComposer,
          $$VocabularyReviewStateTableCreateCompanionBuilder,
          $$VocabularyReviewStateTableUpdateCompanionBuilder,
          (VocabularyReviewStateData, $$VocabularyReviewStateTableReferences),
          VocabularyReviewStateData,
          PrefetchHooks Function({bool learnerId})
        > {
  $$VocabularyReviewStateTableTableManager(
    _$AppDatabase db,
    $VocabularyReviewStateTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VocabularyReviewStateTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$VocabularyReviewStateTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$VocabularyReviewStateTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<int> learnerId = const Value.absent(),
                Value<String?> lexiconId = const Value.absent(),
                Value<String?> chunkId = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<String?> confidenceMarker = const Value.absent(),
                Value<double> easeFactor = const Value.absent(),
                Value<int> intervalDays = const Value.absent(),
                Value<int> repetitions = const Value.absent(),
                Value<DateTime?> dueAt = const Value.absent(),
                Value<DateTime?> lastReviewedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => VocabularyReviewStateCompanion(
                id: id,
                uuid: uuid,
                learnerId: learnerId,
                lexiconId: lexiconId,
                chunkId: chunkId,
                isFavorite: isFavorite,
                confidenceMarker: confidenceMarker,
                easeFactor: easeFactor,
                intervalDays: intervalDays,
                repetitions: repetitions,
                dueAt: dueAt,
                lastReviewedAt: lastReviewedAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String uuid,
                required int learnerId,
                Value<String?> lexiconId = const Value.absent(),
                Value<String?> chunkId = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<String?> confidenceMarker = const Value.absent(),
                Value<double> easeFactor = const Value.absent(),
                Value<int> intervalDays = const Value.absent(),
                Value<int> repetitions = const Value.absent(),
                Value<DateTime?> dueAt = const Value.absent(),
                Value<DateTime?> lastReviewedAt = const Value.absent(),
                required DateTime updatedAt,
              }) => VocabularyReviewStateCompanion.insert(
                id: id,
                uuid: uuid,
                learnerId: learnerId,
                lexiconId: lexiconId,
                chunkId: chunkId,
                isFavorite: isFavorite,
                confidenceMarker: confidenceMarker,
                easeFactor: easeFactor,
                intervalDays: intervalDays,
                repetitions: repetitions,
                dueAt: dueAt,
                lastReviewedAt: lastReviewedAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$VocabularyReviewStateTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({learnerId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (learnerId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.learnerId,
                        referencedTable: $$VocabularyReviewStateTableReferences
                            ._learnerIdTable(db),
                        referencedColumn: $$VocabularyReviewStateTableReferences
                            ._learnerIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$VocabularyReviewStateTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VocabularyReviewStateTable,
      VocabularyReviewStateData,
      $$VocabularyReviewStateTableFilterComposer,
      $$VocabularyReviewStateTableOrderingComposer,
      $$VocabularyReviewStateTableAnnotationComposer,
      $$VocabularyReviewStateTableCreateCompanionBuilder,
      $$VocabularyReviewStateTableUpdateCompanionBuilder,
      (VocabularyReviewStateData, $$VocabularyReviewStateTableReferences),
      VocabularyReviewStateData,
      PrefetchHooks Function({bool learnerId})
    >;
typedef $$GrammarReviewStateTableCreateCompanionBuilder =
    GrammarReviewStateCompanion Function({
      Value<int> id,
      required String uuid,
      required int learnerId,
      required String grammarId,
      Value<bool> isFavorite,
      Value<DateTime?> markedReviewedAt,
      required DateTime updatedAt,
    });
typedef $$GrammarReviewStateTableUpdateCompanionBuilder =
    GrammarReviewStateCompanion Function({
      Value<int> id,
      Value<String> uuid,
      Value<int> learnerId,
      Value<String> grammarId,
      Value<bool> isFavorite,
      Value<DateTime?> markedReviewedAt,
      Value<DateTime> updatedAt,
    });

final class $$GrammarReviewStateTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $GrammarReviewStateTable,
          GrammarReviewStateData
        > {
  $$GrammarReviewStateTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $LearnersTable _learnerIdTable(_$AppDatabase db) =>
      db.learners.createAlias('grammar_review_state__learner_id__learners__id');

  $$LearnersTableProcessedTableManager get learnerId {
    final $_column = $_itemColumn<int>('learner_id')!;

    final manager = $$LearnersTableTableManager(
      $_db,
      $_db.learners,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_learnerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$GrammarReviewStateTableFilterComposer
    extends Composer<_$AppDatabase, $GrammarReviewStateTable> {
  $$GrammarReviewStateTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get grammarId => $composableBuilder(
    column: $table.grammarId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get markedReviewedAt => $composableBuilder(
    column: $table.markedReviewedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$LearnersTableFilterComposer get learnerId {
    final $$LearnersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.learnerId,
      referencedTable: $db.learners,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LearnersTableFilterComposer(
            $db: $db,
            $table: $db.learners,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GrammarReviewStateTableOrderingComposer
    extends Composer<_$AppDatabase, $GrammarReviewStateTable> {
  $$GrammarReviewStateTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get grammarId => $composableBuilder(
    column: $table.grammarId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get markedReviewedAt => $composableBuilder(
    column: $table.markedReviewedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$LearnersTableOrderingComposer get learnerId {
    final $$LearnersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.learnerId,
      referencedTable: $db.learners,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LearnersTableOrderingComposer(
            $db: $db,
            $table: $db.learners,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GrammarReviewStateTableAnnotationComposer
    extends Composer<_$AppDatabase, $GrammarReviewStateTable> {
  $$GrammarReviewStateTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get grammarId =>
      $composableBuilder(column: $table.grammarId, builder: (column) => column);

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get markedReviewedAt => $composableBuilder(
    column: $table.markedReviewedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$LearnersTableAnnotationComposer get learnerId {
    final $$LearnersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.learnerId,
      referencedTable: $db.learners,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LearnersTableAnnotationComposer(
            $db: $db,
            $table: $db.learners,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GrammarReviewStateTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GrammarReviewStateTable,
          GrammarReviewStateData,
          $$GrammarReviewStateTableFilterComposer,
          $$GrammarReviewStateTableOrderingComposer,
          $$GrammarReviewStateTableAnnotationComposer,
          $$GrammarReviewStateTableCreateCompanionBuilder,
          $$GrammarReviewStateTableUpdateCompanionBuilder,
          (GrammarReviewStateData, $$GrammarReviewStateTableReferences),
          GrammarReviewStateData,
          PrefetchHooks Function({bool learnerId})
        > {
  $$GrammarReviewStateTableTableManager(
    _$AppDatabase db,
    $GrammarReviewStateTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GrammarReviewStateTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GrammarReviewStateTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GrammarReviewStateTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<int> learnerId = const Value.absent(),
                Value<String> grammarId = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<DateTime?> markedReviewedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => GrammarReviewStateCompanion(
                id: id,
                uuid: uuid,
                learnerId: learnerId,
                grammarId: grammarId,
                isFavorite: isFavorite,
                markedReviewedAt: markedReviewedAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String uuid,
                required int learnerId,
                required String grammarId,
                Value<bool> isFavorite = const Value.absent(),
                Value<DateTime?> markedReviewedAt = const Value.absent(),
                required DateTime updatedAt,
              }) => GrammarReviewStateCompanion.insert(
                id: id,
                uuid: uuid,
                learnerId: learnerId,
                grammarId: grammarId,
                isFavorite: isFavorite,
                markedReviewedAt: markedReviewedAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$GrammarReviewStateTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({learnerId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (learnerId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.learnerId,
                        referencedTable: $$GrammarReviewStateTableReferences
                            ._learnerIdTable(db),
                        referencedColumn: $$GrammarReviewStateTableReferences
                            ._learnerIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$GrammarReviewStateTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GrammarReviewStateTable,
      GrammarReviewStateData,
      $$GrammarReviewStateTableFilterComposer,
      $$GrammarReviewStateTableOrderingComposer,
      $$GrammarReviewStateTableAnnotationComposer,
      $$GrammarReviewStateTableCreateCompanionBuilder,
      $$GrammarReviewStateTableUpdateCompanionBuilder,
      (GrammarReviewStateData, $$GrammarReviewStateTableReferences),
      GrammarReviewStateData,
      PrefetchHooks Function({bool learnerId})
    >;
typedef $$ContentVersionsTableCreateCompanionBuilder =
    ContentVersionsCompanion Function({
      Value<int> id,
      required String contentVersion,
      required String schemaVersion,
      required String courseId,
      required DateTime installedAt,
      required String unitIdsJson,
      required String lessonIdsJson,
      required String activityIdsJson,
      required String canDoIdsJson,
    });
typedef $$ContentVersionsTableUpdateCompanionBuilder =
    ContentVersionsCompanion Function({
      Value<int> id,
      Value<String> contentVersion,
      Value<String> schemaVersion,
      Value<String> courseId,
      Value<DateTime> installedAt,
      Value<String> unitIdsJson,
      Value<String> lessonIdsJson,
      Value<String> activityIdsJson,
      Value<String> canDoIdsJson,
    });

class $$ContentVersionsTableFilterComposer
    extends Composer<_$AppDatabase, $ContentVersionsTable> {
  $$ContentVersionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentVersion => $composableBuilder(
    column: $table.contentVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get courseId => $composableBuilder(
    column: $table.courseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get installedAt => $composableBuilder(
    column: $table.installedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unitIdsJson => $composableBuilder(
    column: $table.unitIdsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lessonIdsJson => $composableBuilder(
    column: $table.lessonIdsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get activityIdsJson => $composableBuilder(
    column: $table.activityIdsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get canDoIdsJson => $composableBuilder(
    column: $table.canDoIdsJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ContentVersionsTableOrderingComposer
    extends Composer<_$AppDatabase, $ContentVersionsTable> {
  $$ContentVersionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentVersion => $composableBuilder(
    column: $table.contentVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get courseId => $composableBuilder(
    column: $table.courseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get installedAt => $composableBuilder(
    column: $table.installedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unitIdsJson => $composableBuilder(
    column: $table.unitIdsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lessonIdsJson => $composableBuilder(
    column: $table.lessonIdsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get activityIdsJson => $composableBuilder(
    column: $table.activityIdsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get canDoIdsJson => $composableBuilder(
    column: $table.canDoIdsJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ContentVersionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ContentVersionsTable> {
  $$ContentVersionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get contentVersion => $composableBuilder(
    column: $table.contentVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get courseId =>
      $composableBuilder(column: $table.courseId, builder: (column) => column);

  GeneratedColumn<DateTime> get installedAt => $composableBuilder(
    column: $table.installedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get unitIdsJson => $composableBuilder(
    column: $table.unitIdsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lessonIdsJson => $composableBuilder(
    column: $table.lessonIdsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get activityIdsJson => $composableBuilder(
    column: $table.activityIdsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get canDoIdsJson => $composableBuilder(
    column: $table.canDoIdsJson,
    builder: (column) => column,
  );
}

class $$ContentVersionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ContentVersionsTable,
          ContentVersion,
          $$ContentVersionsTableFilterComposer,
          $$ContentVersionsTableOrderingComposer,
          $$ContentVersionsTableAnnotationComposer,
          $$ContentVersionsTableCreateCompanionBuilder,
          $$ContentVersionsTableUpdateCompanionBuilder,
          (
            ContentVersion,
            BaseReferences<
              _$AppDatabase,
              $ContentVersionsTable,
              ContentVersion
            >,
          ),
          ContentVersion,
          PrefetchHooks Function()
        > {
  $$ContentVersionsTableTableManager(
    _$AppDatabase db,
    $ContentVersionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ContentVersionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ContentVersionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ContentVersionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> contentVersion = const Value.absent(),
                Value<String> schemaVersion = const Value.absent(),
                Value<String> courseId = const Value.absent(),
                Value<DateTime> installedAt = const Value.absent(),
                Value<String> unitIdsJson = const Value.absent(),
                Value<String> lessonIdsJson = const Value.absent(),
                Value<String> activityIdsJson = const Value.absent(),
                Value<String> canDoIdsJson = const Value.absent(),
              }) => ContentVersionsCompanion(
                id: id,
                contentVersion: contentVersion,
                schemaVersion: schemaVersion,
                courseId: courseId,
                installedAt: installedAt,
                unitIdsJson: unitIdsJson,
                lessonIdsJson: lessonIdsJson,
                activityIdsJson: activityIdsJson,
                canDoIdsJson: canDoIdsJson,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String contentVersion,
                required String schemaVersion,
                required String courseId,
                required DateTime installedAt,
                required String unitIdsJson,
                required String lessonIdsJson,
                required String activityIdsJson,
                required String canDoIdsJson,
              }) => ContentVersionsCompanion.insert(
                id: id,
                contentVersion: contentVersion,
                schemaVersion: schemaVersion,
                courseId: courseId,
                installedAt: installedAt,
                unitIdsJson: unitIdsJson,
                lessonIdsJson: lessonIdsJson,
                activityIdsJson: activityIdsJson,
                canDoIdsJson: canDoIdsJson,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ContentVersionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ContentVersionsTable,
      ContentVersion,
      $$ContentVersionsTableFilterComposer,
      $$ContentVersionsTableOrderingComposer,
      $$ContentVersionsTableAnnotationComposer,
      $$ContentVersionsTableCreateCompanionBuilder,
      $$ContentVersionsTableUpdateCompanionBuilder,
      (
        ContentVersion,
        BaseReferences<_$AppDatabase, $ContentVersionsTable, ContentVersion>,
      ),
      ContentVersion,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LearnersTableTableManager get learners =>
      $$LearnersTableTableManager(_db, _db.learners);
  $$CourseEnrolmentsTableTableManager get courseEnrolments =>
      $$CourseEnrolmentsTableTableManager(_db, _db.courseEnrolments);
  $$UnitProgressTableTableManager get unitProgress =>
      $$UnitProgressTableTableManager(_db, _db.unitProgress);
  $$LessonProgressTableTableManager get lessonProgress =>
      $$LessonProgressTableTableManager(_db, _db.lessonProgress);
  $$ActivityAttemptsTableTableManager get activityAttempts =>
      $$ActivityAttemptsTableTableManager(_db, _db.activityAttempts);
  $$ActivityAttemptCanDosTableTableManager get activityAttemptCanDos =>
      $$ActivityAttemptCanDosTableTableManager(_db, _db.activityAttemptCanDos);
  $$PlacementAttemptsTableTableManager get placementAttempts =>
      $$PlacementAttemptsTableTableManager(_db, _db.placementAttempts);
  $$FinalMissionAttemptsTableTableManager get finalMissionAttempts =>
      $$FinalMissionAttemptsTableTableManager(_db, _db.finalMissionAttempts);
  $$FinalAssessmentAttemptsTableTableManager get finalAssessmentAttempts =>
      $$FinalAssessmentAttemptsTableTableManager(
        _db,
        _db.finalAssessmentAttempts,
      );
  $$VocabularyReviewStateTableTableManager get vocabularyReviewState =>
      $$VocabularyReviewStateTableTableManager(_db, _db.vocabularyReviewState);
  $$GrammarReviewStateTableTableManager get grammarReviewState =>
      $$GrammarReviewStateTableTableManager(_db, _db.grammarReviewState);
  $$ContentVersionsTableTableManager get contentVersions =>
      $$ContentVersionsTableTableManager(_db, _db.contentVersions);
}
