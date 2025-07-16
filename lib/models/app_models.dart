int? _parseIntFromDynamic(dynamic value) {
  if (value is int) {
    return value;
  } else if (value is String) {
    return int.tryParse(value);
  }
  return null;
}

// --- API Response Models ---
class ApiResponse<T> {
  final String message;
  final T? data;
  final Map<String, dynamic>? errors;
  final int? statusCode;

  ApiResponse({required this.message, this.data, this.errors, this.statusCode});

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json) fromJsonT,
  ) {
    int? parsedStatusCode;
    if (json.containsKey('status_code')) {
      parsedStatusCode = _parseIntFromDynamic(json['status_code']);
    }
    final String parsedMessage =
        json['message'] as String? ?? 'An unexpected error occurred.';

    return ApiResponse(
      message: parsedMessage,
      data: json['data'] != null ? fromJsonT(json['data']) : null,
      errors: json['errors'] as Map<String, dynamic>?,
      statusCode: parsedStatusCode,
    );
  }

  factory ApiResponse.fromError(
    String message, {
    int? statusCode,
    Map<String, dynamic>? errors,
  }) {
    return ApiResponse(
      message: message,
      statusCode: statusCode,
      errors: errors,
    );
  }
}

// --- Authentication Models ---
class AuthResponse {
  final String message;
  final AuthData? data;

  AuthResponse({required this.message, this.data});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      message:
          json['message'] as String? ??
          'Authentication response message missing.',
      data:
          json['data'] != null
              ? AuthData.fromJson(json['data'] as Map<String, dynamic>)
              : null,
    );
  }
}

class AuthData {
  final String token;
  final User user;

  AuthData({required this.token, required this.user});

  factory AuthData.fromJson(Map<String, dynamic> json) {
    return AuthData(
      token: json['token'] as String,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {'token': token, 'user': user.toJson()};
  }
}

// --- User Profile Models ---
class User {
  final int id;
  final String name;
  final String email;
  final String? batch_ke;
  final String? training_title;
  final String? jenis_kelamin;
  final String? profile_photo;
  final DateTime? emailVerifiedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? batchId;
  final int? trainingId;
  final Batch? batch;
  final Training? training;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.batch_ke,
    this.training_title,
    this.jenis_kelamin,
    this.profile_photo,
    this.emailVerifiedAt,
    this.createdAt,
    this.updatedAt,
    this.batchId,
    this.trainingId,
    this.batch,
    this.training,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: _parseIntFromDynamic(json['id']) ?? 0,
      name: json['name'] as String? ?? 'Unknown Name',
      email: json['email'] as String? ?? 'unknown@example.com',
      batch_ke: json['batch_ke'] as String?,
      training_title: json['training_title'] as String?,
      jenis_kelamin: json['jenis_kelamin'] as String?,
      profile_photo: json['profile_photo'] as String?,
      emailVerifiedAt:
          json['email_verified_at'] != null
              ? DateTime.tryParse(json['email_verified_at'] as String)
              : null,
      createdAt:
          json['created_at'] != null
              ? DateTime.tryParse(json['created_at'] as String)
              : null,
      updatedAt:
          json['updated_at'] != null
              ? DateTime.tryParse(json['updated_at'] as String)
              : null,
      batchId: _parseIntFromDynamic(json['batch_id']),
      trainingId: _parseIntFromDynamic(json['training_id']),
      batch:
          json['batch'] != null
              ? Batch.fromJson(json['batch'] as Map<String, dynamic>)
              : null,
      training:
          json['training'] != null
              ? Training.fromJson(json['training'] as Map<String, dynamic>)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'batch_ke': batch_ke,
      'training_title': training_title,
      'jenis_kelamin': jenis_kelamin,
      'profile_photo': profile_photo,
      'email_verified_at': emailVerifiedAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'batch_id': batchId,
      'training_id': trainingId,
      'batch': batch?.toJson(),
      'training': training?.toJson(),
    };
  }
}

// --- Attendance Models ---
class Absence {
  final int id;
  final int userId;
  final DateTime? checkIn;
  final String? checkInLocation;
  final String? checkInAddress;
  final DateTime? checkOut;
  final String? checkOutLocation;
  final String? checkOutAddress;
  final String? status;
  final String? alasanIzin;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final double? checkInLat;
  final double? checkInLng;
  final double? checkOutLat;
  final double? checkOutLng;
  final DateTime? attendanceDate;

  Absence({
    required this.id,
    required this.userId,
    this.checkIn,
    this.checkInLocation,
    this.checkInAddress,
    this.checkOut,
    this.checkOutLocation,
    this.checkOutAddress,
    this.status,
    this.alasanIzin,
    this.createdAt,
    this.updatedAt,
    this.checkInLat,
    this.checkInLng,
    this.checkOutLat,
    this.checkOutLng,
    this.attendanceDate,
  });

  factory Absence.fromJson(Map<String, dynamic> json) {
    final String? attendanceDateStr = json['attendance_date'] as String?;
    final String? checkInTimeStr = json['check_in_time'] as String?;
    final String? checkOutTimeStr = json['check_out_time'] as String?;

    DateTime? parsedCheckIn;
    if (attendanceDateStr != null && checkInTimeStr != null) {
      parsedCheckIn = DateTime.tryParse('$attendanceDateStr $checkInTimeStr');
    }

    DateTime? parsedCheckOut;
    if (attendanceDateStr != null && checkOutTimeStr != null) {
      parsedCheckOut = DateTime.tryParse('$attendanceDateStr $checkOutTimeStr');
    }
    final int parsedId = _parseIntFromDynamic(json['id']) ?? 0;
    final int parsedUserId = _parseIntFromDynamic(json['user_id']) ?? 0;

    return Absence(
      id: parsedId,
      userId: parsedUserId,
      checkIn: parsedCheckIn,
      checkInLocation: json['check_in_location'] as String?,
      checkInAddress: json['check_in_address'] as String?,
      checkOut: parsedCheckOut,
      checkOutLocation: json['check_out_location'] as String?,
      checkOutAddress: json['check_out_address'] as String?,
      status: json['status'] as String?,
      alasanIzin: json['alasan_izin'] as String?,
      createdAt:
          json['created_at'] != null
              ? DateTime.tryParse(json['created_at'] as String)
              : null,
      updatedAt:
          json['updated_at'] != null
              ? DateTime.tryParse(json['updated_at'] as String)
              : null,
      checkInLat: (json['check_in_lat'] as num?)?.toDouble(),
      checkInLng: (json['check_in_lng'] as num?)?.toDouble(),
      checkOutLat: (json['check_out_lat'] as num?)?.toDouble(),
      checkOutLng: (json['check_out_lng'] as num?)?.toDouble(),
      attendanceDate:
          attendanceDateStr != null
              ? DateTime.tryParse(attendanceDateStr)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'check_in_time': checkIn?.toLocal().toIso8601String().substring(11, 19),
      'check_in_location': checkInLocation,
      'check_in_address': checkInAddress,
      'check_out_time': checkOut?.toLocal().toIso8601String().substring(11, 19),
      'check_out_location': checkOutLocation,
      'check_out_address': checkOutAddress,
      'status': status,
      'alasan_izin': alasanIzin,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'check_in_lat': checkInLat,
      'check_in_lng': checkInLng,
      'check_out_lat': checkOutLat,
      'check_out_lng': checkOutLng,
      'attendance_date': attendanceDate?.toIso8601String().substring(0, 10),
    };
  }
}

class AbsenceToday {
  final DateTime? tanggal;
  final DateTime? jamMasuk;
  final DateTime? jamKeluar;
  final String? alamatMasuk;
  final String? alamatKeluar;
  final String? status;
  final String? alasanIzin;
  final DateTime? attendanceDate;

  AbsenceToday({
    this.tanggal,
    this.jamMasuk,
    this.jamKeluar,
    this.alamatMasuk,
    this.alamatKeluar,
    this.status,
    this.alasanIzin,
    this.attendanceDate,
  });

  factory AbsenceToday.fromJson(Map<String, dynamic> json) {
    final String? attendanceDateStr = json['attendance_date'] as String?;
    final String? checkInTimeStr = json['check_in_time'] as String?;
    final String? checkOutTimeStr = json['check_out_time'] as String?;

    DateTime? parsedJamMasuk;
    if (attendanceDateStr != null && checkInTimeStr != null) {
      parsedJamMasuk = DateTime.tryParse('$attendanceDateStr $checkInTimeStr');
    }

    DateTime? parsedJamKeluar;
    if (attendanceDateStr != null && checkOutTimeStr != null) {
      parsedJamKeluar = DateTime.tryParse(
        '$attendanceDateStr $checkOutTimeStr',
      );
    }

    return AbsenceToday(
      tanggal:
          attendanceDateStr != null
              ? DateTime.tryParse(attendanceDateStr)
              : null,
      jamMasuk: parsedJamMasuk,
      jamKeluar: parsedJamKeluar,
      alamatMasuk: json['check_in_address'] as String?,
      alamatKeluar: json['check_out_address'] as String?,
      status: json['status'] as String?,
      alasanIzin: json['alasan_izin'] as String?,
      attendanceDate:
          attendanceDateStr != null
              ? DateTime.tryParse(attendanceDateStr)
              : null,
    );
  }
}

class AbsenceStats {
  final int totalAbsen;
  final int totalMasuk;
  final int totalIzin;
  final bool sudahAbsenHariIni;

  AbsenceStats({
    required this.totalAbsen,
    required this.totalMasuk,
    required this.totalIzin,
    required this.sudahAbsenHariIni,
  });

  factory AbsenceStats.fromJson(Map<String, dynamic> json) {
    return AbsenceStats(
      totalAbsen: _parseIntFromDynamic(json['total_absen']) ?? 0,
      totalMasuk: _parseIntFromDynamic(json['total_masuk']) ?? 0,
      totalIzin: _parseIntFromDynamic(json['total_izin']) ?? 0,
      sudahAbsenHariIni: json['sudah_absen_hari_ini'] as bool? ?? false,
    );
  }
}

// --- Batch and Training Models ---
class Batch {
  final int id;
  final String batch_ke;
  final String? startDate;
  final String? endDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<Training>? trainings;
  Batch({
    required this.id,
    required this.batch_ke,
    this.startDate,
    this.endDate,
    this.createdAt,
    this.updatedAt,
    this.trainings,
  });

  factory Batch.fromJson(Map<String, dynamic> json) {
    return Batch(
      id: _parseIntFromDynamic(json['id']) ?? 0,
      batch_ke: json['batch_ke'] as String? ?? 'N/A',
      startDate: json['start_date'] as String?,
      endDate: json['end_date'] as String?,
      createdAt:
          json['created_at'] != null
              ? DateTime.tryParse(json['created_at'] as String)
              : null,
      updatedAt:
          json['updated_at'] != null
              ? DateTime.tryParse(json['updated_at'] as String)
              : null,
      trainings:
          (json['trainings'] as List<dynamic>?)
              ?.map((e) => Training.fromJson(e as Map<String, dynamic>))
              .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'batch_ke': batch_ke,
      'start_date': startDate,
      'end_date': endDate,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'trainings': trainings?.map((e) => e.toJson()).toList(),
    };
  }
}

class Training {
  final int id;
  final String title;
  final String? description;
  final int? participantCount;
  final String? standard;
  final String? duration;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<dynamic>? units;
  final List<dynamic>? activities;

  Training({
    required this.id,
    required this.title,
    this.description,
    this.participantCount,
    this.standard,
    this.duration,
    this.createdAt,
    this.updatedAt,
    this.units,
    this.activities,
  });

  factory Training.fromJson(Map<String, dynamic> json) {
    return Training(
      id: _parseIntFromDynamic(json['id']) ?? 0,
      title: json['title'] as String? ?? 'N/A',
      description: json['description'] as String?,
      participantCount: _parseIntFromDynamic(
        json['participant_count'],
      ), // Use helper
      standard: json['standard'] as String?,
      duration: json['duration'] as String?,
      createdAt:
          json['created_at'] != null
              ? DateTime.tryParse(json['created_at'] as String)
              : null,
      updatedAt:
          json['updated_at'] != null
              ? DateTime.tryParse(json['updated_at'] as String)
              : null,
      units: json['units'] as List<dynamic>?,
      activities: json['activities'] as List<dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'participant_count': participantCount,
      'standard': standard,
      'duration': duration,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'units': units,
      'activities': activities,
    };
  }
}
