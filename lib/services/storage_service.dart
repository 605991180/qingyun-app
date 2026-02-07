import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/contact.dart';
import '../models/diary.dart';
import '../models/contact_resource.dart';

class StorageService {
  static const String _contactsKey = 'contacts_v2';
  static const String _diariesKey = 'diaries_v1';
  static const String _resourcesKey = 'contact_resources_v1';

  // ========== 联系人相关 ==========
  
  static Future<List<Contact>> loadContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_contactsKey);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => Contact.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveContacts(List<Contact> contacts) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(contacts.map((c) => c.toJson()).toList());
    await prefs.setString(_contactsKey, jsonString);
  }

  static Future<void> addContact(Contact contact) async {
    final contacts = await loadContacts();
    final existing = contacts.where((c) => c.name == contact.name);
    if (existing.isEmpty) {
      contacts.add(contact);
      await saveContacts(contacts);
    }
  }

  static Future<void> updateContact(Contact contact) async {
    final contacts = await loadContacts();
    final index = contacts.indexWhere((c) => c.id == contact.id);
    if (index != -1) {
      contacts[index] = contact;
    } else {
      contacts.add(contact);
    }
    await saveContacts(contacts);
  }

  static Future<void> deleteContact(String id) async {
    final contacts = await loadContacts();
    contacts.removeWhere((c) => c.id == id);
    await saveContacts(contacts);
    // 同时删除该联系人的资源
    final resources = await loadContactResources();
    resources.removeWhere((r) => r.contactId == id);
    await saveContactResources(resources);
  }

  static Future<Contact?> getContact(String id) async {
    final contacts = await loadContacts();
    try {
      return contacts.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  // ========== 日记相关 ==========

  static Future<List<Diary>> loadDiaries() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_diariesKey);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => Diary.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveDiaries(List<Diary> diaries) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(diaries.map((d) => d.toJson()).toList());
    await prefs.setString(_diariesKey, jsonString);
  }

  static Future<void> addDiary(Diary diary) async {
    final diaries = await loadDiaries();
    diaries.add(diary);
    await saveDiaries(diaries);
  }

  static Future<void> updateDiary(Diary diary) async {
    final diaries = await loadDiaries();
    final index = diaries.indexWhere((d) => d.id == diary.id);
    if (index != -1) {
      diaries[index] = diary;
    } else {
      diaries.add(diary);
    }
    await saveDiaries(diaries);
  }

  static Future<void> deleteDiary(String id) async {
    final diaries = await loadDiaries();
    diaries.removeWhere((d) => d.id == id);
    await saveDiaries(diaries);
  }

  static Future<Diary?> getDiary(String id) async {
    final diaries = await loadDiaries();
    try {
      return diaries.firstWhere((d) => d.id == id);
    } catch (e) {
      return null;
    }
  }

  static Future<List<Diary>> getDiariesByDate(DateTime date) async {
    final diaries = await loadDiaries();
    return diaries.where((d) =>
        d.date.year == date.year &&
        d.date.month == date.month &&
        d.date.day == date.day).toList();
  }

  // ========== 人脉资源相关 ==========

  static Future<List<ContactResource>> loadContactResources() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_resourcesKey);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => ContactResource.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveContactResources(List<ContactResource> resources) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(resources.map((r) => r.toJson()).toList());
    await prefs.setString(_resourcesKey, jsonString);
  }

  static Future<void> addContactResource(ContactResource resource) async {
    final resources = await loadContactResources();
    // 避免重复添加相同资源
    final exists = resources.any((r) => 
      r.contactId == resource.contactId && 
      r.category == resource.category &&
      r.description == resource.description
    );
    if (!exists) {
      resources.add(resource);
      await saveContactResources(resources);
    }
  }

  static Future<void> deleteContactResource(String id) async {
    final resources = await loadContactResources();
    resources.removeWhere((r) => r.id == id);
    await saveContactResources(resources);
  }

  static Future<List<ContactResource>> getResourcesByContact(String contactId) async {
    final resources = await loadContactResources();
    return resources.where((r) => r.contactId == contactId).toList();
  }

  static Future<List<ContactResource>> getResourcesByCategory(ResourceCategory category) async {
    final resources = await loadContactResources();
    return resources.where((r) => r.category == category).toList();
  }

  static Future<Map<ResourceCategory, List<ContactResource>>> getResourcesGroupedByCategory() async {
    final resources = await loadContactResources();
    final grouped = <ResourceCategory, List<ContactResource>>{};
    for (var category in ResourceCategory.values) {
      grouped[category] = resources.where((r) => r.category == category).toList();
    }
    return grouped;
  }

  // ========== 通用 ==========

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_contactsKey);
    await prefs.remove(_diariesKey);
    await prefs.remove(_resourcesKey);
  }
}
