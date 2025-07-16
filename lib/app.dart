import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'providers/person_provider.dart';
import 'providers/debt_provider.dart';
import 'providers/installment_provider.dart';
import 'providers/internet_provider.dart';
import 'providers/backup_provider.dart';
import 'screens/home_screen.dart';

class StoreManagementApp extends StatelessWidget {
  const StoreManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => PersonProvider()),
        ChangeNotifierProvider(create: (context) => DebtProvider()),
        ChangeNotifierProvider(create: (context) => InstallmentProvider()),
        ChangeNotifierProvider(create: (context) => InternetProvider()),
        ChangeNotifierProvider(create: (context) => BackupProvider()),
      ],
      child: MaterialApp(
        title: 'إدارة المحل',
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('ar', ''), // Arabic, no country code
        ],
        locale: const Locale('ar', ''),
        theme: ThemeData(
          primarySwatch: Colors.blue,
          fontFamily: 'Arial',
          textTheme: const TextTheme(
            headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            bodyLarge: TextStyle(fontSize: 16),
            bodyMedium: TextStyle(fontSize: 14),
            bodySmall: TextStyle(fontSize: 12),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          dataTableTheme: DataTableThemeData(
            headingRowColor: MaterialStateProperty.all(Colors.grey[100]),
            dataRowColor: MaterialStateProperty.resolveWith((states) {
              if (states.contains(MaterialState.selected)) {
                return Colors.blue[50];
              }
              return null;
            }),
          ),
        ),
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
