import 'package:drift/wasm.dart';

// Compiled with:
//   dart compile js -O4 web/drift_worker.dart -o web/drift_worker.dart.js
void main() => WasmDatabase.workerMainForOpen();
