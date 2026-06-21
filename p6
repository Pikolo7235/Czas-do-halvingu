            <canvas id="progressChart"></canvas>
            <div id="percentageLabel" class="percentage-label">0%</div>
        </div>

        <div class="countdown">
            <div><span id="days" class="num">00</span><span class="unit">Dni</span></div>
            <div><span id="hours" class="num">00</span><span class="unit">Godz</span></div>
            <div><span id="minutes" class="num">00</span><span class="unit">Min</span></div>
            <div><span id="seconds" class="num">00</span><span class="unit">Sek</span></div>
        </div>

        <!-- Kalkulator Opłat Sieciowych z Wyborem Waluty i LocalStorage -->
        <div class="fee-calculator" style="margin-top: 15px; border-top: 1px solid #333; padding-top: 15px; text-align: left; font-size: 0.8rem;">
            <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px;">
                <span style="color: #f7931a; font-weight: bold; text-transform: uppercase; letter-spacing: 0.5px;">Kalkulator Opłat (vB)</span>
                <!-- Selektor Walut -->
                <select id="currencySelector" style="background: #2d2d2d; color: #fff; border: 1px solid #f7931a; border-radius: 4px; padding: 2px 5px; font-size: 0.75rem; cursor: pointer;">
                    <option value="PLN">PLN (zł)</option>
                    <option value="USD">USD ($)</option>
                    <option value="EUR">EUR (€)</option>
                </select>
            </div>
            
            <div style="display: flex; justify-content: space-between; margin-bottom: 5px;">
                <span>Priorytet Niski:</span>
                <strong id="feeLow">- sat/vB (<span id="feeLowFiat">-</span> <span class="currency-unit">PLN</span>)</strong>
            </div>
            <div style="display: flex; justify-content: space-between; margin-bottom: 5px;">
                <span>Priorytet Średni:</span>
                <strong id="feeMedium" style="color: #ffb74d;">- sat/vB (<span id="feeMediumFiat">-</span> <span class="currency-unit">PLN</span>)</strong>
            </div>
            <div style="display: flex; justify-content: space-between;">
                <span>Priorytet Wysoki:</span>
                <strong id="feeHigh" style="color: #f7931a;">- sat/vB (<span id="feeHighFiat">-</span> <span class="currency-unit">PLN</span>)</strong>
            </div>
        </div>

        <div class="block-info">
            Aktualny blok: <span id="currentBlock">-</span><br>
            Pozostało bloków: <span id="blocksRemaining">-</span><br>
            Docelowy blok: <strong>1 050 000</strong>
        </div>
    </div>
</div>

<script src="https://jsdelivr.net"></script>
<script>
    const START_BLOCK = 840000;  // Halving 2024
    const TARGET_BLOCK = 1050000; // Halving 2028
    const BLOCKS_IN_CYCLE = TARGET_BLOCK - START_BLOCK;
    const BLOCK_TIME_MS = 10 * 60 * 1000; // Średnio 10 minut na blok
    const TX_SIZE_VB = 140; // Średni rozmiar standardowej transakcji

    let chart;
    let msRemaining = 0;
    let btcToFiatPrice = 0;
    let currentCurrency = 'PLN';

    function updateChart(progressPercent) {
        const ctx = document.getElementById('progressChart').getContext('2d');
        if (!chart) {
            chart = new Chart(ctx, {
                type: 'doughnut',
                data: {
                    datasets: [{
                        data: [progressPercent, 100 - progressPercent],
                        backgroundColor: ['#f7931a', '#2d2d2d'],
                        borderWidth: 0
                    }]
                },
                options: {
                    cutout: '85%',
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: { legend: { display: false }, tooltip: { enabled: false } }
                }
            });
        } else {
            chart.data.datasets.data = [progressPercent, 100 - progressPercent];
            chart.update();
        }
    }

    function updateCountdownVisuals() {
        if (msRemaining < 0) msRemaining = 0;
        const days = Math.floor(msRemaining / (1000 * 60 * 60 * 24));
        const hours = Math.floor((msRemaining % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
        const minutes = Math.floor((msRemaining % (1000 * 60 * 60)) / (1000 * 60));
        const seconds = Math.floor((msRemaining % (1000 * 60)) / 1000);

        document.getElementById('days').innerText = String(days).padStart(2, '0');
        document.getElementById('hours').innerText = String(hours).padStart(2, '0');
        document.getElementById('minutes').innerText = String(minutes).padStart(2, '0');
        document.getElementById('seconds').innerText = String(seconds).padStart(2, '0');
    }

    async function fetchFiatPrice() {
        const symbol = currentCurrency === 'USD' ? 'BTCUSDT' : `BTC${currentCurrency}`;
        try {
            const response = await fetch(`https://binance.com{symbol}`);
            if (response.ok) {
                const data = await response.json();
                btcToFiatPrice = parseFloat(data.price);
            }
        } catch (e) {
            console.error('Błąd Binance, fallback do CoinGecko:', e);
            try {
                const res = await fetch(`https://coingecko.com{currentCurrency.toLowerCase()}`);
                const data = await res.json();
                btcToFiatPrice = data.bitcoin[currentCurrency.toLowerCase()];
            } catch(err) { console.error('Błąd awaryjnego API:', err); }
        }
    }

    async function fetchFeeEstimates() {
        try {
            const response = await fetch('https://mempool.space');
            if (!response.ok) return;
            const fees = await response.json();

            document.getElementById('feeLow').childNodes.nodeValue = `${fees.hourFee} sat/vB `;
            document.getElementById('feeMedium').childNodes.nodeValue = `${fees.halfHourFee} sat/vB `;
            document.getElementById('feeHigh').childNodes.nodeValue = `${fees.fastestFee} sat/vB `;

            const unitLabels = document.querySelectorAll('.currency-unit');
            unitLabels.forEach(label => label.innerText = currentCurrency);

            if (btcToFiatPrice > 0) {
                const satoshiInFiat = btcToFiatPrice / 100000000;
                
                const costLowFiat = fees.hourFee * TX_SIZE_VB * satoshiInFiat;
                const costMediumFiat = fees.halfHourFee * TX_SIZE_VB * satoshiInFiat;
                const costHighFiat = fees.fastestFee * TX_SIZE_VB * satoshiInFiat;

                document.getElementById('feeLowFiat').innerText = costLowFiat.toFixed(2);
                document.getElementById('feeMediumFiat').innerText = costMediumFiat.toFixed(2);
                document.getElementById('feeHighFiat').innerText = costHighFiat.toFixed(2);
            }
        } catch (e) {
            console.error('Błąd kalkulatora opłat:', e);
        }
    }

    async function fetchBitcoinData() {
        try {
            const response = await fetch('https://blockstream.info');
            if (!response.ok) throw new Error('Błąd sieci');
            
            const currentBlock = parseInt(await response.text(), 10);
            const blocksRemaining = TARGET_BLOCK - currentBlock;
            const blocksMinedInCycle = currentBlock - START_BLOCK;
            
            const progressPercent = Math.min(Math.max((blocksMinedInCycle / BLOCKS_IN_CYCLE) * 100, 0), 100);
            msRemaining = blocksRemaining * BLOCK_TIME_MS;

            document.getElementById('currentBlock').innerText = currentBlock.toLocaleString();
            document.getElementById('blocksRemaining').innerText = blocksRemaining.toLocaleString();
            document.getElementById('percentageLabel').innerText = progressPercent.toFixed(2) + '%';
            
            document.getElementById('loader').style.display = 'none';
            document.getElementById('content').style.display = 'block';

            updateChart(progressPercent);

            await fetchFiatPrice();
            await fetchFeeEstimates();

        } catch (error) {
            console.error('Błąd główny aplikacji:', error);
            if (!chart) {
                document.getElementById('loader').innerText = 'Błąd ładowania danych sieci BTC.';
            }
        }
    }

    document.addEventListener('DOMContentLoaded', () => {
        // Odczytanie zapisanej waluty z LocalStorage (domyślnie PLN)
        const savedCurrency = localStorage.getItem('btc_fiat_currency');
        if (savedCurrency) {
            currentCurrency = savedCurrency;
            document.getElementById('currencySelector').value = savedCurrency;
        }

        fetchBitcoinData();

        document.getElementById('currencySelector').addEventListener('change', async (e) => {
            currentCurrency = e.target.value;
            // Zapisanie nowego wyboru użytkownika do LocalStorage
            localStorage.setItem('btc_fiat_currency', currentCurrency);
            
            await fetchFiatPrice();
            await fetchFeeEstimates();
        });

        setInterval(() => {
            if (msRemaining > 0) {
                msRemaining -= 1000;
                updateCountdownVisuals();
            }
        }, 1000);

        setInterval(fetchBitcoinData, 60000); 
    });
</script>
</body>
</html>
