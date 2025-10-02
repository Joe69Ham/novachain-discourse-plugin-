# ✅ NovaChain Energy Plugin - Update auf External Transfer API

## 🎯 Änderungen

### 1. **Neuer API Endpoint**
- **Alt:** `https://mjeqsapfdnpufhkquzhn.supabase.co/functions/v1/energy-points`
- **Neu:** `https://mjeqsapfdnpufhkquzhn.supabase.co/functions/v1/external-energy-transfer`

### 2. **Authentication**
- **Alt:** `Authorization: Bearer <api_key>` + `apikey` Header
- **Neu:** `x-api-key: <api_key>` (nur ein Header)

### 3. **Request Format**
```json
{
  "action": "transfer",
  "wallet_address": "0x...",
  "energy_amount": 5000,
  "user_id": 123,
  "username": "joe69",
  "timestamp": 1727823456,
  "source": "discourse_forum"
}
```

### 4. **Response Format**
```json
{
  "success": true,
  "message": "Energy points transferred successfully",
  "data": {
    "wallet_address": "0x...",
    "previous_balance": 1000,
    "transferred_amount": 5000,
    "new_balance": 6000,
    "source": "discourse_forum",
    "timestamp": "2025-10-02T12:34:56.789Z"
  }
}
```

## 🔧 Setup Schritte

### 1. API Key generieren
```bash
openssl rand -hex 32
```

**Beispiel Output:**
```
a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456
```

### 2. Supabase Secret setzen
```bash
cd /dein/supabase/projekt
npx supabase secrets set EXTERNAL_TRANSFER_API_KEY=a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456
```

### 3. Discourse Plugin konfigurieren

1. **In Discourse Admin gehen:**
   ```
   https://nova-chain.io/admin/site_settings/category/plugins?filter=novachain
   ```

2. **API Key setzen:**
   - Setting: `novachain_api_key`
   - Value: `a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456`
   - (Derselbe Key wie in Supabase!)

3. **Plugin aktivieren:**
   - Setting: `novachain_enabled`
   - Value: ✅ aktiviert

## 🧪 Testing

### Manuelle Tests mit cURL
```bash
# Test 1: Valider Transfer
curl -X POST https://mjeqsapfdnpufhkquzhn.supabase.co/functions/v1/external-energy-transfer \
  -H "Content-Type: application/json" \
  -H "x-api-key: DEIN_API_KEY" \
  -d '{
    "action": "transfer",
    "wallet_address": "0xeb3c3cb8df4b76e88739db345fb92bd38e6840d3",
    "energy_amount": 5000,
    "user_id": 123,
    "username": "testuser",
    "source": "discourse_forum"
  }'

# Test 2: Invalider API Key (sollte 401 geben)
curl -X POST https://mjeqsapfdnpufhkquzhn.supabase.co/functions/v1/external-energy-transfer \
  -H "Content-Type: application/json" \
  -H "x-api-key: FALSCHER_KEY" \
  -d '{
    "action": "transfer",
    "wallet_address": "0xeb3c3cb8df4b76e88739db345fb92bd38e6840d3",
    "energy_amount": 100,
    "source": "test"
  }'

# Test 3: Fehlende Fields (sollte 400 geben)
curl -X POST https://mjeqsapfdnpufhkquzhn.supabase.co/functions/v1/external-energy-transfer \
  -H "Content-Type: application/json" \
  -H "x-api-key: DEIN_API_KEY" \
  -d '{
    "action": "transfer",
    "energy_amount": 100
  }'

# Test 4: Ungültiger Amount > 10000 (sollte 400 geben)
curl -X POST https://mjeqsapfdnpufhkquzhn.supabase.co/functions/v1/external-energy-transfer \
  -H "Content-Type: application/json" \
  -H "x-api-key: DEIN_API_KEY" \
  -d '{
    "action": "transfer",
    "wallet_address": "0xeb3c3cb8df4b76e88739db345fb92bd38e6840d3",
    "energy_amount": 15000,
    "source": "test"
  }'
```

### Automatisierte Tests (Python)
```bash
cd /opt/novachain-community

# 1. Setze deinen API Key im Script
nano test_external_transfer.py
# Ändere: API_KEY = "YOUR_SECRET_API_KEY_HERE"
# zu:     API_KEY = "a1b2c3d4e5..."

# 2. Führe Tests aus
python3 test_external_transfer.py
```

**Erwartete Output:**
```
🧪 NovaChain External Energy Transfer API Test
============================================================

🔄 Testing Transfer:
   URL: https://mjeqsapfdnpufhkquzhn.supabase.co/functions/v1/external-energy-transfer
   Wallet: 0xeb3c3cb8df4b76e88739db345fb92bd38e6840d3
   Amount: 5000 EP
   User: joe69 (ID: 123)

📥 Response Status: 200
✅ SUCCESS!
{
  "success": true,
  "message": "Energy points transferred successfully",
  "data": {
    "wallet_address": "0xeb3c3cb8df4b76e88739db345fb92bd38e6840d3",
    "previous_balance": 0,
    "transferred_amount": 5000,
    "new_balance": 5000,
    ...
  }
}

📊 Balance Update:
   Previous: 0 EP
   Transferred: 5000 EP
   New Balance: 5000 EP

============================================================
📊 Test Summary
============================================================
   ✅ PASS - valid_transfer
   ✅ PASS - invalid_api_key
   ✅ PASS - missing_fields
   ✅ PASS - invalid_amount

   Total: 4/4 Tests Passed

✅ API Integration erfolgreich!
```

## 🔄 Plugin Flow

### Automatischer Transfer bei 5000 EP

1. **User macht Aktivität** (z.B. Post erstellen)
   ```
   Post erstellt → +3 EP
   ```

2. **Plugin updated Balance**
   ```ruby
   current_balance = 4998 EP
   new_balance = 5001 EP (4998 + 3)
   ```

3. **Auto-Transfer Check**
   ```ruby
   pending = 5001 - 0 = 5001 EP
   if pending >= 5000:
     trigger_blockchain_transfer()
   ```

4. **API Call zu Supabase**
   ```bash
   POST /external-energy-transfer
   {
     "action": "transfer",
     "wallet_address": "0xeb3c...",
     "energy_amount": 5001,
     "user_id": 123,
     "username": "joe69",
     "source": "discourse_forum"
   }
   ```

5. **Supabase verarbeitet**
   - Validiert API Key
   - Validiert Amount (1-10000)
   - Erstellt/Updated Wallet
   - Loggt Activity
   - Gibt neue Balance zurück

6. **Plugin speichert Transfer**
   ```ruby
   energy_transferred = 5001
   last_transfer_at = 1727823456
   pending = 0
   ```

7. **User bekommt Notification**
   ```
   ✅ 5001 Energy Points transferred to your wallet!
   Wallet: 0xeb3c...
   ```

## 📊 Monitoring

### Discourse Logs
```bash
# Plugin geladen?
sudo docker exec app tail -f /var/www/discourse/log/production.log | grep NovaChain

# Transfers?
sudo docker exec app tail -f /var/www/discourse/log/production.log | grep "AUTO-TRANSFER"

# Errors?
sudo docker exec app tail -f /var/www/discourse/log/production.log | grep "ERROR\|Exception"
```

### Supabase Dashboard
```sql
-- Alle External Transfers
SELECT * FROM energy_actions 
WHERE action_key = 'external_transfer' 
ORDER BY created_at DESC 
LIMIT 50;

-- Transfers pro Source
SELECT source, COUNT(*), SUM(amount) as total_ep
FROM energy_actions 
WHERE action_key = 'external_transfer'
GROUP BY source;

-- Letzte Transfers für User
SELECT wallet_address, amount, created_at
FROM energy_actions 
WHERE wallet_address = '0xeb3c...'
ORDER BY created_at DESC
LIMIT 10;
```

## ⚠️ Troubleshooting

### Error: 401 Unauthorized
```
❌ Ursache: API Key falsch oder nicht gesetzt
✅ Lösung: 
   1. Prüfe Supabase Secret: npx supabase secrets list
   2. Prüfe Discourse Setting: /admin/site_settings (novachain_api_key)
   3. Keys müssen identisch sein!
```

### Error: 400 Missing required fields
```
❌ Ursache: wallet_address, energy_amount oder source fehlt
✅ Lösung: Prüfe Plugin Request Body in /var/www/discourse/plugins/.../plugin.rb
```

### Error: Transfer nicht ausgelöst
```
❌ Ursache: User hat keine Wallet verknüpft
✅ Lösung: User muss erst Wallet linken:
   POST /novachain/link-wallet
   {"wallet_address": "0x..."}
```

### Error: 400 Invalid energy_amount
```
❌ Ursache: Amount > 10000
✅ Lösung: API akzeptiert max 10.000 EP pro Transfer
   Plugin sollte bei Bedarf mehrere Transfers machen
```

## 🔒 Security Best Practices

1. **API Key nie im Code committen**
   - Nur in Supabase Secrets und Discourse Settings
   - Nicht in Git, nicht in Logs

2. **Rate Limiting aktivieren**
   - Supabase Edge Functions haben eingebautes Rate Limiting
   - Zusätzlich: Discourse Plugin kann max 1 Transfer/Minute/User

3. **Wallet Validation**
   - Plugin prüft Format: 40-64 hex characters
   - Supabase erstellt automatisch User wenn nicht vorhanden

4. **Activity Logging**
   - Alle Transfers werden in `energy_actions` geloggt
   - Metadata für Debugging/Audit

## 📈 Next Steps

1. ✅ **Plugin deployed** - Läuft auf deinem Discourse
2. ⏳ **API Key setzen** - In Supabase + Discourse
3. ⏳ **Testing** - Mit test_external_transfer.py
4. ⏳ **Monitoring** - Logs + Supabase Dashboard
5. 🎯 **Live gehen** - Users können Wallets linken!

## 🚀 Go Live Checklist

- [ ] Supabase Secret gesetzt: `EXTERNAL_TRANSFER_API_KEY`
- [ ] Discourse Setting gesetzt: `novachain_api_key`
- [ ] Plugin enabled: `novachain_enabled`
- [ ] API Tests erfolgreich (4/4)
- [ ] Discourse Logs zeigen Plugin geladen
- [ ] Test-User kann Wallet linken
- [ ] Test-User erhält Energy Points
- [ ] Auto-Transfer bei 5000 EP funktioniert
- [ ] Monitoring Setup (Logs + Supabase)

---

**Status:** ✅ Plugin aktualisiert und deployed!
**Version:** 1.1.0
**Last Update:** 2025-10-02
