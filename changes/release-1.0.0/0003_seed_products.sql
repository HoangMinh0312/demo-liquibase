INSERT INTO ${AppSchema}.products (id, sku, name, description, unit_price, currency)
VALUES
    ('0a3f1c2e-9b1d-4e7a-8c21-1f6d2a9b0001', 'SKU-ENVELOPE-A4', 'Envelope A4',         'Standard A4 envelope, pack of 50',   4.50, 'USD'),
    ('0a3f1c2e-9b1d-4e7a-8c21-1f6d2a9b0002', 'SKU-BOX-S',       'Shipping Box Small',  '20x15x10 cm corrugated box',         1.20, 'USD'),
    ('0a3f1c2e-9b1d-4e7a-8c21-1f6d2a9b0003', 'SKU-BOX-M',       'Shipping Box Medium', '40x30x20 cm corrugated box',         2.40, 'USD'),
    ('0a3f1c2e-9b1d-4e7a-8c21-1f6d2a9b0004', 'SKU-LABEL-ROLL',  'Label Roll',          'Thermal shipping labels, 500/roll',  9.90, 'USD'),
    ('0a3f1c2e-9b1d-4e7a-8c21-1f6d2a9b0005', 'SKU-TAPE',        'Packing Tape',        '48mm x 66m clear tape',              1.75, 'USD')
ON CONFLICT (id) DO NOTHING;
