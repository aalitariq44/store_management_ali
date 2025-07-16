import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/person_model.dart';
import '../models/debt_model.dart';
import '../models/installment_model.dart';
import '../models/internet_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Initialize ffi
    sqfliteFfiInit();

    // Get the database path
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'store_management.db');

    // Open the database
    databaseFactory = databaseFactoryFfi;
    return await openDatabase(
      path,
      version: 3, // Update version number
      onCreate: _createTables,
      onUpgrade: _onUpgrade,
      onOpen: (db) async {
        // Enable foreign key constraints
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Create incomes table if upgrading from version 1 to 2
      await db.execute('''
        CREATE TABLE incomes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          amount REAL NOT NULL,
          description TEXT NOT NULL,
          date INTEGER NOT NULL
        )
      ''');
    }
    
    if (oldVersion < 3) {
      // Create app_password table if upgrading from version 2 to 3
      await db.execute('''
        CREATE TABLE app_password (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          hashed_password TEXT NOT NULL,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''');
    }
  }

  Future<void> _createTables(Database db, int version) async {
    // Create persons table
    await db.execute('''
      CREATE TABLE persons (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        address TEXT,
        notes TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Create debts table
    await db.execute('''
      CREATE TABLE debts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        person_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        paid_amount REAL DEFAULT 0.0,
        notes TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        is_paid INTEGER DEFAULT 0,
        FOREIGN KEY (person_id) REFERENCES persons (id) ON DELETE CASCADE
      )
    ''');

    // Create installments table
    await db.execute('''
      CREATE TABLE installments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        person_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        total_amount REAL NOT NULL,
        paid_amount REAL DEFAULT 0.0,
        notes TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        is_completed INTEGER DEFAULT 0,
        FOREIGN KEY (person_id) REFERENCES persons (id) ON DELETE CASCADE
      )
    ''');

    // Create installment_payments table
    await db.execute('''
      CREATE TABLE installment_payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        installment_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        notes TEXT,
        payment_date INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (installment_id) REFERENCES installments (id) ON DELETE CASCADE
      )
    ''');

    // Create internet_subscriptions table
    await db.execute('''
      CREATE TABLE internet_subscriptions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        person_id INTEGER NOT NULL,
        package_name TEXT NOT NULL,
        price REAL NOT NULL,
        paid_amount REAL NOT NULL,
        duration_in_days INTEGER NOT NULL,
        start_date INTEGER NOT NULL,
        end_date INTEGER NOT NULL,
        payment_date INTEGER NOT NULL,
        notes TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        is_active INTEGER DEFAULT 1,
        FOREIGN KEY (person_id) REFERENCES persons (id) ON DELETE CASCADE
      )
    ''');
    
    // Create incomes table
    await db.execute('''
      CREATE TABLE incomes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        description TEXT NOT NULL,
        date INTEGER NOT NULL
      )
    ''');
    
    // Create app_password table
    await db.execute('''
      CREATE TABLE app_password (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        hashed_password TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
  }

  // CRUD operations for Person
  Future<int> insertPerson(Person person) async {
    final db = await database;
    return await db.insert('persons', person.toMap());
  }

  Future<List<Person>> getAllPersons() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('persons');
    return List.generate(maps.length, (i) => Person.fromMap(maps[i]));
  }

  Future<Person?> getPersonById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'persons',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Person.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updatePerson(Person person) async {
    final db = await database;
    return await db.update(
      'persons',
      person.toMap(),
      where: 'id = ?',
      whereArgs: [person.id],
    );
  }

  Future<int> deletePerson(int id) async {
    final db = await database;
    
    // Start a transaction to ensure all related data is deleted
    return await db.transaction((txn) async {
      // Delete internet subscriptions
      await txn.delete(
        'internet_subscriptions',
        where: 'person_id = ?',
        whereArgs: [id],
      );
      
      // Delete installment payments first (child table)
      await txn.rawDelete('''
        DELETE FROM installment_payments 
        WHERE installment_id IN (
          SELECT id FROM installments WHERE person_id = ?
        )
      ''', [id]);
      
      // Delete installments
      await txn.delete(
        'installments',
        where: 'person_id = ?',
        whereArgs: [id],
      );
      
      // Delete debts
      await txn.delete(
        'debts',
        where: 'person_id = ?',
        whereArgs: [id],
      );
      
      // Finally delete the person
      return await txn.delete(
        'persons',
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  Future<List<Person>> searchPersons(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'persons',
      where: 'name LIKE ? OR phone LIKE ? OR address LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
    );
    return List.generate(maps.length, (i) => Person.fromMap(maps[i]));
  }

  // CRUD operations for Debt
  Future<int> insertDebt(Debt debt) async {
    final db = await database;
    return await db.insert('debts', debt.toMap());
  }

  Future<List<Debt>> getAllDebts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'debts',
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => Debt.fromMap(maps[i]));
  }

  Future<List<Debt>> getDebtsByPersonId(int personId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'debts',
      where: 'person_id = ?',
      whereArgs: [personId],
    );
    return List.generate(maps.length, (i) => Debt.fromMap(maps[i]));
  }

  Future<int> updateDebt(Debt debt) async {
    final db = await database;
    return await db.update(
      'debts',
      debt.toMap(),
      where: 'id = ?',
      whereArgs: [debt.id],
    );
  }

  Future<int> deleteDebt(int id) async {
    final db = await database;
    return await db.delete(
      'debts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // CRUD operations for Installment
  Future<int> insertInstallment(Installment installment) async {
    final db = await database;
    return await db.insert('installments', installment.toMap());
  }

  Future<List<Installment>> getAllInstallments() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('installments');
    return List.generate(maps.length, (i) => Installment.fromMap(maps[i]));
  }

  Future<List<Installment>> getInstallmentsByPersonId(int personId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'installments',
      where: 'person_id = ?',
      whereArgs: [personId],
    );
    return List.generate(maps.length, (i) => Installment.fromMap(maps[i]));
  }

  Future<int> updateInstallment(Installment installment) async {
    final db = await database;
    return await db.update(
      'installments',
      installment.toMap(),
      where: 'id = ?',
      whereArgs: [installment.id],
    );
  }

  Future<int> deleteInstallment(int id) async {
    final db = await database;
    return await db.delete(
      'installments',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // CRUD operations for InstallmentPayment
  Future<int> insertInstallmentPayment(InstallmentPayment payment) async {
    final db = await database;
    return await db.insert('installment_payments', payment.toMap());
  }

  Future<List<InstallmentPayment>> getInstallmentPayments(int installmentId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'installment_payments',
      where: 'installment_id = ?',
      whereArgs: [installmentId],
    );
    return List.generate(maps.length, (i) => InstallmentPayment.fromMap(maps[i]));
  }

  Future<int> deleteInstallmentPayment(int id) async {
    final db = await database;
    return await db.delete(
      'installment_payments',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // CRUD operations for InternetSubscription
  Future<int> insertInternetSubscription(InternetSubscription subscription) async {
    final db = await database;
    return await db.insert('internet_subscriptions', subscription.toMap());
  }

  Future<List<InternetSubscription>> getAllInternetSubscriptions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('internet_subscriptions');
    return List.generate(maps.length, (i) => InternetSubscription.fromMap(maps[i]));
  }

  Future<List<InternetSubscription>> getInternetSubscriptionsByPersonId(int personId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'internet_subscriptions',
      where: 'person_id = ?',
      whereArgs: [personId],
    );
    return List.generate(maps.length, (i) => InternetSubscription.fromMap(maps[i]));
  }

  Future<int> updateInternetSubscription(InternetSubscription subscription) async {
    final db = await database;
    return await db.update(
      'internet_subscriptions',
      subscription.toMap(),
      where: 'id = ?',
      whereArgs: [subscription.id],
    );
  }

  Future<int> deleteInternetSubscription(int id) async {
    final db = await database;
    return await db.delete(
      'internet_subscriptions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  // Reset database instance
  void resetDatabase() {
    _database = null;
  }
}
