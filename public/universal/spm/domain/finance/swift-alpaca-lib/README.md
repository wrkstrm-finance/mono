# AlpacaLib

Swift-native Alpaca REST client plus CommonBroker adapters.

The adapter targets Alpaca paper-trading credentials by default and keeps the
live environment available through `AlpacaEnvironment.live`.

- Auth status from configured API key/secret presence.
- Local secret storage for paper/live API credential blobs.
- Account lookup via Trading API `/v2/account`.
- Latest stock quote snapshots via Market Data API.
- Open positions via Trading API `/v2/positions`.
- Basic order placement, replacement, cancellation, status, and open-order listing.
- Market clock/calendar and stock bars mapped as time-sales.
- Account activities and simple FIFO-derived gain/loss.
- Active asset lookup for reference search.
- Watchlist list/create/add/remove/delete.
- Option contracts plus option snapshots/chain using the indicative feed by default.

## Products

- `AlpacaLib`: native client and Alpaca response/request models.
- `AlpacaBrokerageCommonAdapters`: `CommonBroker` service adapters for quotes,
  account/profile, positions, orders, market, activity, reference, watchlists,
  and options.

## Limits

- Quote support currently maps Alpaca latest quote bid/ask fields; it does not
  fetch latest trades/bars for last price yet.
- `CommonOrderService.previewOrder` throws because Alpaca does not expose an
  order-preview endpoint.
- `CommonInterval.tick` maps to 1-minute Alpaca bars because the CommonBroker
  time-sales shape is OHLC-oriented.
- Streaming services are not implemented in this adapter pass.

## Local Development

```sh
swift test
```

The package resolves `CommonBroker` from the local mono checkout when available.
