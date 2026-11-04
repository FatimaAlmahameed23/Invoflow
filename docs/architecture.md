# Feature layers

Login is the reference for all five features: login, invoice, add invoice,
invoice details, and settings.

```text
Page / widget → Cubit → Use case → Repository interface
                                      ↓
                               Repository implementation
                                      ↓
                                  Data source → Backend
```

- Presentation calls Cubit methods and renders state. Navigation and SnackBars
  run in listeners. Widget controllers and temporary visual state stay in widgets.
- Cubits call use cases and emit states; each state file is a part of its Cubit.
- Use cases depend on domain repository interfaces. Domain entities describe
  app data and have no Flutter, Supabase, or data-layer dependencies.
- Repositories build request models and convert response models into entities.
  Conversion includes status enums, dates, numbers, and backend field aliases.
- Data sources handle backend calls and return response models. Response models
  describe backend fields and validate their shape without inheriting entities.
- Request serialization lives in `data/models/request`; backend response models
  live in `data/models/response`.
- `core/di` constructs data sources, repositories, use cases, and Cubits. Pages
  contain no repository, use-case, API-client, or Supabase construction.

Auth is provided above the navigator. Other Cubits are scoped to their feature
views, and BlocProvider closes them when those views are removed. Login uses
distinct loading/success/failure states; forms and lists retain composite state
where multiple values or operations must remain visible together.
