# InnovaFit iOS

Proyecto iOS para el sistema InnovaFit. Esta app utiliza Swift + SwiftUI y está preparada para pruebas automáticas con Codex y CI.

## ✅ Requisitos

- Xcode 15 o superior
- Swift 5.9+
- iOS 17+
- Simulador: iPhone 15 (o cambia en el script)

## 🚀 Ejecutar tests

```bash
./run_tests.sh
```

## 🌐 Universal Links

La app soporta abrir máquinas directamente desde un Universal Link que incluya
el parámetro `tag`. Un enlace válido se ve así:

```
https://link.innovafit.pe/?tag=tag_001
```

Al abrirlo, la app carga la máquina y el gimnasio asociados y navega
automáticamente a `MachineScreenContent2`.
