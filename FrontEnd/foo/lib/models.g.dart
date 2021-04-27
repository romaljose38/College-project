// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserAdapter extends TypeAdapter<User> {
  @override
  final int typeId = 0;

  @override
  User read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return User(
      name: fields[0] as String,
    );
  }

  @override
  void write(BinaryWriter writer, User obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.name);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ChatMessageAdapter extends TypeAdapter<ChatMessage> {
  @override
  final int typeId = 1;

  @override
  ChatMessage read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChatMessage(
      thread: fields[0] as Thread,
      message: fields[1] as String,
      time: fields[2] as DateTime,
      id: fields[5] as int,
      senderName: fields[3] as String,
      isMe: fields[6] as bool,
      msgType: fields[7] as String,
      base64string: fields[8] as String,
      ext: fields[9] as String,
    )..haveReceived = fields[4] as bool;
  }

  @override
  void write(BinaryWriter writer, ChatMessage obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.thread)
      ..writeByte(1)
      ..write(obj.message)
      ..writeByte(2)
      ..write(obj.time)
      ..writeByte(3)
      ..write(obj.senderName)
      ..writeByte(4)
      ..write(obj.haveReceived)
      ..writeByte(5)
      ..write(obj.id)
      ..writeByte(6)
      ..write(obj.isMe)
      ..writeByte(7)
      ..write(obj.msgType)
      ..writeByte(8)
      ..write(obj.base64string)
      ..writeByte(9)
      ..write(obj.ext);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMessageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ThreadAdapter extends TypeAdapter<Thread> {
  @override
  final int typeId = 2;

  @override
  Thread read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Thread(
      first: fields[0] as User,
      second: fields[1] as User,
    )
      ..chatList = (fields[2] as List)?.cast<ChatMessage>()
      ..lastAccessed = fields[3] as DateTime;
  }

  @override
  void write(BinaryWriter writer, Thread obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.first)
      ..writeByte(1)
      ..write(obj.second)
      ..writeByte(2)
      ..write(obj.chatList)
      ..writeByte(3)
      ..write(obj.lastAccessed);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThreadAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
