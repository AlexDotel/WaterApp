# Hydra

Aplicación minimalista y moderna en **Flutter** para llevar el control diario de hidratación, metas, rachas y recordatorios inteligentes, diseñada con la tipografía **DM Sans** y soporte automático para **Modo Claro y Modo Oscuro**.

## Funcionalidades principales

- **Visualizador líquido animado:** Esfera minimalista con doble ola animada (`CustomPainter`) que refleja tu progreso diario en vasos, volumen (`ml` / `oz`) y porcentaje.
- **Registro en 1 toque + Deshacer:** Añade un vaso, medio vaso o botella rápidamente con retroalimentación háptica y opción de deshacer al instante.
- **Factor de hidratación por bebida:** Registra agua (`100%`), agua con gas (`100%`), té/infusión (`95%`), café (`80%`) o electrolitos (`110%`).
- **Ritmo inteligente del día (Pacing):** Te indica en tiempo real si vas adelantado, al ritmo ideal o si un vaso ahora te pone al día según tu horario activo.
- **Rachas + Escudo de Racha (Streak Freeze):** Lleva tu racha actual y mejor racha histórica; cada 7 días cumplidos ganas un escudo que protege automáticamente tu racha si un día te falla el registro.
- **Progreso visual y logros:** Gráfica semanal de 7 días con línea de meta, calendario *heatmap* de 28 días e insignias minimalistas desbloqueables.
- **Recordatorios inteligentes:** Notificaciones locales programadas en tu horario activo que se silencian automáticamente para el resto del día en cuanto cumples tu meta.
- **Onboarding con calculadora de meta:** Calcula tu meta diaria recomendada según peso corporal y nivel de actividad.

## Ejecutar localmente

```bash
flutter pub get
flutter run
```

## Pruebas y análisis estático

```bash
flutter analyze
flutter test
```
