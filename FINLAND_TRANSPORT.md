# Integración de Transporte Externo (Finlandia)

Este documento detalla cómo Jombo API integra servicios de transporte externos para la región de Finlandia (`fi`).

## 🚆 API de Digitransit

Jombo utiliza la API de **Digitransit (Routing API v2)** para ofrecer alternativas de transporte cuando no hay viajes de carpooling disponibles.

### Componentes:
1. **Geocoding API (v1)**: Convierte los nombres de ciudades (ej: "Helsinki") en coordenadas geográficas.
2. **Routing API (v2)**: Realiza consultas GraphQL para obtener itinerarios reales de trenes (VR), buses y transporte regional.

### Endpoint:
- Routing: `https://api.digitransit.fi/routing/v2/finland/gtfs/v1`
- Geocoding: `https://api.digitransit.fi/geocoding/v1/search`

## 🧠 Lógica de Funcionamiento

Cuando un usuario realiza una búsqueda en la región `fi`:

1. Se buscan viajes en la base de datos de Jombo.
2. Independientemente de si hay resultados o no, se consulta a Digitransit (a través de `ExternalTransportService`).
3. La respuesta incluye dos listas: `trips` (Jombo) y `external_options` (Digitransit).

### Formato de Respuesta (`fi`):
```json
{
  "trips": [...],
  "external_options": [
    {
      "type": "external_transport",
      "start_time": "2026-03-03T14:30:00Z",
      "duration": 7800,
      "legs": [
        { "mode": "WALK", "from": "Origin", "to": "Station" },
        { "mode": "RAIL", "from": "Turku", "to": "Helsinki", "route": "S 964" }
      ]
    }
  ]
}
```

## ⚡️ Optimización y Caching

Para mejorar el rendimiento y evitar llamadas innecesarias:
- Las consultas externas se guardan en el caché de Rails por **30 minutos** usando una clave basada en el origen y destino: `external_transport/origen/destino`.

## 📈 Analítica de Demanda (SearchLog)

Cada vez que un usuario busca una ruta en Finlandia y **no encuentra viajes locales**, el sistema registra la búsqueda en la tabla `search_logs`.

Esto permite:
- Identificar rutas con alta demanda sin oferta.
- Notificar a conductores potenciales en esas zonas.
- Analizar el crecimiento necesario de la plataforma.

## 🔑 Configuración

Es necesario configurar la clave de API en las variables de entorno:
- `DIGITRANSIT_API_KEY`: Clave obtenida en el portal de desarrolladores de Digitransit.
