            <canvas id="progressChart"></canvas>
            <div id="percentageLabel" class="percentage-label">0%</div>
        </div>

        <div class="countdown">
            <div><span id="days" class="num">00</span><span class="unit">Dni</span></div>
            <div><span id="hours" class="num">00</span><span class="unit">Godz</span></div>
            <div><span id="minutes" class="num">00</span><span class="unit">Min</span></div>
            <div><span id="seconds" class="num">00</span><span class="unit">Sek</span></div>
        </div>

        <!-- Kalkulator Opłat Sieciowych (Nowa Sekcja) -->
        <div class="fee-calculator" style="margin-top: 15px; border-top: 1px solid #333; padding-top: 15px; text-align: left; font-size: 0.8rem;">
            <div style="color: #f7931a; font-weight: bold; margin-bottom: 8px; text-align: center; text-transform: uppercase; letter-spacing: 0.5px;">Kalkulator Opłat (vB)</div>
            <div style="display: flex; justify-content: space-between; margin-bottom: 5px;">
                <span>Priorytet Niski:</span>
                <strong id="feeLow">- sat/vB (<span id="feeLowFiat">-</span> PLN)</strong>
            </div>
            <div style="display: flex; justify-content: space-between; margin-bottom: 5px;">
                <span>Priorytet Średni:</span>
                <strong id="feeMedium" style="color: #ffb74d;">- sat/vB (<span id="feeMediumFiat">-</span> PLN)</strong>
            </div>
            <div style="display: flex; justify-content: space-between;">
                <span>Priorytet Wysoki:</span>
                <strong id="feeHigh" style="color: #f7931a;">- sat/vB (<span id="feeHighFiat">-</span> PLN)</strong>
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
    const TX_SIZE_VB = 140; // Średni rozmiar standardowej transakcji SegWit (1 wejście, 2 wyjścia)

    let chart;
    let msRemaining = 0;
    let btcToPlnPrice = 0;

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
            chart.data.datasets[0].data = [progressPercent, 100 - progressPercent];
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

    // Pobieranie aktualnej ceny rynkowej BTC w PLN (z giełdy Binance)
    async function fetchFiatPrice() {
        try {
            const response = await fetch('https://binance.com');
            if (response.ok) {
                const data = await response.json();
                btcToPlnPrice = parseFloat(data.price);
            }
        } catch (e) {
            console.error('Błąd pobierania kursu PLN:', e);
            // Rezerwowe API na wypadek problemów (Coingecko)
            try {
                const res = await fetch('https://coingecko.com');
                const data = await res.json();
                btcToPlnPrice = data.bitcoin.pln;
            } catch(err) { console.error(err); }
        }
    }

    // Pobieranie opłat transakcyjnych sat/vB z Mempool.space i przeliczanie na PLN
    async function fetchFeeEstimates() {
        try {
            const response = await fetch('https://mempool.space');
            if (!response.ok) return;
            const fees = await response.json();

            document.getElementById('feeLow').childNodes[0].nodeValue = `${fees.hourFee} sat/vB `;
            document.getElementById('feeMedium').childNodes[0].nodeValue = `${fees.halfHourFee} sat/vB `;
            document.getElementById('feeHigh').childNodes[0].nodeValue = `${fees.fastestFee} sat/vB `;

            if (btcToPlnPrice > 0) {
                const satoshiInPln = btcToPlnPrice / 100000000;
                
                const costLowPln = fees.hourFee * TX_SIZE_VB * satoshiInPln;
                const costMediumPln = fees.halfHourFee * TX_SIZE_VB * satoshiInPln;
                const costHighPln = fees.fastestFee * TX_SIZE_VB * satoshiInPln;

                document.getElementById('feeLowFiat').innerText = costLowPln.toFixed(2);
                document.getElementById('feeMediumFiat').innerText = costMediumPln.toFixed(2);
                document.getElementById('feeHighFiat').innerText = costHighPln.toFixed(2);
            }
        } catch (e) {
            console.error('Błąd pobierania estymacji opłat:', e);
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

            // Po aktualizacji bloku, zaktualizuj też wyceny finansowe
            await fetchFiatPrice();
            await fetchFeeEstimates();

        } catch (error) {
            console.error('Błąd:', error);
            if (!chart) {
                document.getElementById('loader').innerText = 'Błąd ładowania danych sieci BTC.';
            }
        }
    }

    document.addEventListener('DOMContentLoaded', () => {
        fetchBitcoinData();

        // 1. Zegar odliczający sekundy
        setInterval(() => {
            if (msRemaining > 0) {
                msRemaining -= 1000;
                updateCountdownVisuals();
            }
        }, 1000);

        // 2. Automatyczne odświeżanie danych o bloku, cenie i opłatach (co 60 sekund)
        setInterval(fetchBitcoinData, 60000); 
    });
</script>
</body>
</html>
