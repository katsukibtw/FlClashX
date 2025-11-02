import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flclashx/common/common.dart';
import 'package:flclashx/enum/enum.dart';
import 'package:path/path.dart';
import 'package:win32/win32.dart';

class Windows {
  static Windows? _instance;
  late DynamicLibrary _shell32;
  late DynamicLibrary _uxtheme;

  Windows._internal() {
    _shell32 = DynamicLibrary.open('shell32.dll');
    try {
      _uxtheme = DynamicLibrary.open('uxtheme.dll');
    } catch (e) {
      // Ignore if uxtheme.dll is not available
    }
  }

  factory Windows() {
    _instance ??= Windows._internal();
    return _instance!;
  }

  bool isDarkMode() {
    try {
      final keyPath = 'Software\\Microsoft\\Windows\\CurrentVersion\\Themes\\Personalize'.toNativeUtf16();
      final valueName = 'AppsUseLightTheme'.toNativeUtf16();
      
      final phkResult = calloc<HKEY>();
      var result = RegOpenKeyEx(
        HKEY_CURRENT_USER,
        keyPath,
        0,
        REG_SAM_FLAGS.KEY_READ,
        phkResult,
      );
      
      calloc.free(keyPath);
      
      if (result != WIN32_ERROR.ERROR_SUCCESS) {
        calloc.free(valueName);
        calloc.free(phkResult);
        return false;
      }
      
      final hKey = phkResult.value;
      calloc.free(phkResult);
      
      final data = calloc<DWORD>();
      final dataSize = calloc<DWORD>();
      dataSize.value = sizeOf<DWORD>();
      
      result = RegQueryValueEx(
        hKey,
        valueName,
        nullptr,
        nullptr,
        data.cast(),
        dataSize,
      );
      
      calloc.free(valueName);
      RegCloseKey(hKey);
      
      if (result != WIN32_ERROR.ERROR_SUCCESS) {
        calloc.free(data);
        calloc.free(dataSize);
        return false;
      }
      
      final isLightMode = data.value != 0;
      calloc.free(data);
      calloc.free(dataSize);
      
      return !isLightMode;
    } catch (e) {
      return false;
    }
  }

  void enableDarkModeForApp() {
    try {
      final isDark = isDarkMode();
      if (!isDark) return;
      
      // Пытаемся использовать недокументированное API для темной темы
      // Эти функции существуют только как ordinals в uxtheme.dll
      try {
        final kernel32 = DynamicLibrary.open('kernel32.dll');
        final moduleName = 'uxtheme.dll'.toNativeUtf16();
        
        // Получаем GetProcAddress напрямую из kernel32
        final getProcAddressFunc = kernel32.lookupFunction<
            IntPtr Function(IntPtr hModule, Pointer<Utf8> lpProcName),
            int Function(int hModule, Pointer<Utf8> lpProcName)>('GetProcAddress');
        
        final getModuleHandleFunc = kernel32.lookupFunction<
            IntPtr Function(Pointer<Utf16> lpModuleName),
            int Function(Pointer<Utf16> lpModuleName)>('GetModuleHandleW');
        
        final uxthemeHandle = getModuleHandleFunc(moduleName);
        calloc.free(moduleName);
        
        if (uxthemeHandle != 0) {
          // Для ordinals используем MAKEINTRESOURCE: младшие 16 бит
          // Ordinal 135 = SetPreferredAppMode (Windows 10 1903+)
          final ordinal135 = Pointer<Utf8>.fromAddress(135);
          final setPreferredAppModePtr = getProcAddressFunc(uxthemeHandle, ordinal135);
          
          if (setPreferredAppModePtr != 0) {
            final setPreferredAppMode = Pointer<NativeFunction<Int32 Function(Int32)>>
                .fromAddress(setPreferredAppModePtr)
                .asFunction<int Function(int)>();
            setPreferredAppMode(1); // 1 = AllowDark
          } else {
            // Ordinal 133 = AllowDarkModeForApp (Windows 10 1809)
            final ordinal133 = Pointer<Utf8>.fromAddress(133);
            final allowDarkModePtr = getProcAddressFunc(uxthemeHandle, ordinal133);
            
            if (allowDarkModePtr != 0) {
              final allowDarkModeForApp = Pointer<NativeFunction<Int32 Function(Int32)>>
                  .fromAddress(allowDarkModePtr)
                  .asFunction<int Function(int)>();
              allowDarkModeForApp(1); // TRUE
            }
          }
          
          // Ordinal 136 = FlushMenuThemes
          final ordinal136 = Pointer<Utf8>.fromAddress(136);
          final flushMenuThemesPtr = getProcAddressFunc(uxthemeHandle, ordinal136);
          
          if (flushMenuThemesPtr != 0) {
            final flushMenuThemes = Pointer<NativeFunction<Void Function()>>
                .fromAddress(flushMenuThemesPtr)
                .asFunction<void Function()>();
            flushMenuThemes();
          }
        }
      } catch (e) {
        // Ignore if functions are not available
      }
    } catch (e) {
      // Ignore errors
    }
  }

  void applyDarkModeToMenu(int hwnd) {
    if (hwnd == 0) return;
    
    try {
      final isDark = isDarkMode();
      
      // Попытка применить темную тему через SetWindowTheme
      final themeName = isDark ? 'DarkMode_Explorer'.toNativeUtf16() : nullptr;
      
      try {
        final setWindowTheme = _uxtheme.lookupFunction<
            Int32 Function(IntPtr hwnd, Pointer<Utf16> pszSubAppName, Pointer<Utf16> pszSubIdList),
            int Function(int hwnd, Pointer<Utf16> pszSubAppName, Pointer<Utf16> pszSubIdList)>('SetWindowTheme');
        
        setWindowTheme(hwnd, themeName, nullptr);
      } catch (e) {
        // Ignore if SetWindowTheme is not available
      }
      
      if (themeName != nullptr) {
        calloc.free(themeName);
      }
    } catch (e) {
      // Ignore errors
    }
  }

  bool runas(String command, String arguments) {
    final commandPtr = command.toNativeUtf16();
    final argumentsPtr = arguments.toNativeUtf16();
    final operationPtr = 'runas'.toNativeUtf16();

    final shellExecute = _shell32.lookupFunction<
        Int32 Function(
            Pointer<Utf16> hwnd,
            Pointer<Utf16> lpOperation,
            Pointer<Utf16> lpFile,
            Pointer<Utf16> lpParameters,
            Pointer<Utf16> lpDirectory,
            Int32 nShowCmd),
        int Function(
            Pointer<Utf16> hwnd,
            Pointer<Utf16> lpOperation,
            Pointer<Utf16> lpFile,
            Pointer<Utf16> lpParameters,
            Pointer<Utf16> lpDirectory,
            int nShowCmd)>('ShellExecuteW');

    final result = shellExecute(
      nullptr,
      operationPtr,
      commandPtr,
      argumentsPtr,
      nullptr,
      1,
    );

    calloc.free(commandPtr);
    calloc.free(argumentsPtr);
    calloc.free(operationPtr);

    commonPrint.log("windows runas: $command $arguments resultCode:$result");

    if (result < 42) {
      return false;
    }
    return true;
  }

  _killProcess(int port) async {
    final result = await Process.run('netstat', ['-ano']);
    final lines = result.stdout.toString().trim().split('\n');
    for (final line in lines) {
      if (!line.contains(":$port") || !line.contains("LISTENING")) {
        continue;
      }
      final parts = line.trim().split(RegExp(r'\s+'));
      final pid = int.tryParse(parts.last);
      if (pid != null) {
        await Process.run('taskkill', ['/PID', pid.toString(), '/F']);
      }
    }
  }

  Future<WindowsHelperServiceStatus> checkService() async {
    // final qcResult = await Process.run('sc', ['qc', appHelperService]);
    // final qcOutput = qcResult.stdout.toString();
    // if (qcResult.exitCode != 0 || !qcOutput.contains(appPath.helperPath)) {
    //   return WindowsHelperServiceStatus.none;
    // }
    final result = await Process.run('sc', ['query', appHelperService]);
    if(result.exitCode != 0){
      return WindowsHelperServiceStatus.none;
    }
    final output = result.stdout.toString();
    if (output.contains("RUNNING") && await request.pingHelper()) {
      return WindowsHelperServiceStatus.running;
    }
    return WindowsHelperServiceStatus.presence;
  }

  Future<bool> registerService() async {
    final status = await checkService();

    if (status == WindowsHelperServiceStatus.running) {
      return true;
    }

    await _killProcess(helperPort);

    final command = [
      "/c",
      if (status == WindowsHelperServiceStatus.presence) ...[
        "sc",
        "delete",
        appHelperService,
        "/force",
        "&&",
      ],
      "sc",
      "create",
      appHelperService,
      'binPath= "${appPath.helperPath}"',
      'start= auto',
      "&&",
      "sc",
      "start",
      appHelperService,
    ].join(" ");

    final res = runas("cmd.exe", command);

    await Future.delayed(
      const Duration(milliseconds: 300),
    );

    return res;
  }

  Future<bool> startService() async {
    final status = await checkService();
    
    if (status == WindowsHelperServiceStatus.running) {
      return true;
    }

    if (status == WindowsHelperServiceStatus.none) {
      return false;
    }

    final result = await Process.run('sc', ['start', appHelperService]);
    
    if (result.exitCode == 0) {
      await Future.delayed(const Duration(milliseconds: 500));
      return true;
    }
    
    return false;
  }

  Future<bool> stopService() async {
    final status = await checkService();
    
    if (status == WindowsHelperServiceStatus.none) {
      return true;
    }

    final result = await Process.run('sc', ['stop', appHelperService]);
    
    if (result.exitCode == 0) {
      await Future.delayed(const Duration(milliseconds: 500));
      return true;
    }
    
    return false;
  }

  Future<bool> registerTask(String appName) async {
    final taskXml = '''
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.3" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <Principals>
    <Principal id="Author">
      <LogonType>InteractiveToken</LogonType>
      <RunLevel>HighestAvailable</RunLevel>
    </Principal>
  </Principals>
  <Triggers>
    <LogonTrigger/>
  </Triggers>
  <Settings>
    <MultipleInstancesPolicy>Parallel</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
    <AllowHardTerminate>false</AllowHardTerminate>
    <StartWhenAvailable>false</StartWhenAvailable>
    <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
    <IdleSettings>
      <StopOnIdleEnd>false</StopOnIdleEnd>
      <RestartOnIdle>false</RestartOnIdle>
    </IdleSettings>
    <AllowStartOnDemand>true</AllowStartOnDemand>
    <Enabled>true</Enabled>
    <Hidden>false</Hidden>
    <RunOnlyIfIdle>false</RunOnlyIfIdle>
    <WakeToRun>false</WakeToRun>
    <ExecutionTimeLimit>PT72H</ExecutionTimeLimit>
    <Priority>7</Priority>
  </Settings>
  <Actions Context="Author">
    <Exec>
      <Command>"${Platform.resolvedExecutable}"</Command>
    </Exec>
  </Actions>
</Task>''';
    final taskPath = join(await appPath.tempPath, "task.xml");
    await File(taskPath).create(recursive: true);
    await File(taskPath)
        .writeAsBytes(taskXml.encodeUtf16LeWithBom, flush: true);
    final commandLine = [
      '/Create',
      '/TN',
      appName,
      '/XML',
      "%s",
      '/F',
    ].join(" ");
    return runas(
      'schtasks',
      commandLine.replaceFirst("%s", taskPath),
    );
  }
}

final windows = Platform.isWindows ? Windows() : null;
