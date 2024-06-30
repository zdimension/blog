---
title: "What's in my Location History?"
excerpt: "Getting my location history from Google and analyzing it with Python."
tags: [Programming, Data Science]
---

I've been using Google Maps' location history feature for a few years now. It's a bit creepy to think about how much data Google has about me, but it's also a goldmine for data analysis. 

Kindly enough, Google allows me to download all of my precious data in machine-readable format using [Google Takeout](https://takeout.google.com/settings/takeout):

![Google Takeout UI with the Location History item](chrome_bhSzpJGu6j.png)

This gives us a bunch of JSON files:

```bash
$ ls -R
.:
 Records.json  'Semantic Location History'   Settings.json  'Timeline Edits.json'

'./Semantic Location History':
2012  2015  2017  2019  2021  2023
2014  2016  2018  2020  2022  2024
```

## First look at the data

That first `Records.json` file here is almost a gigabyte for my account. Not surprising, given that it contains 10-odd years of location data. It contains every single "phone home" location data packet that my phone has sent to Google. 

### Unprocessed data

Here's a packet from it:

```json
{
    "latitudeE7": 460734187,
    "longitudeE7": 67312122,
    "accuracy": 3198,
    "activity": [
        {
            "activity": [
                {
                    "type": "STILL",
                    "confidence": 100
                }
            ],
            "timestamp": "2014-04-28T12:34:46.342Z"
        }
    ],
    "source": "CELL",
    "deviceTag": 803364441,
    "timestamp": "2014-04-28T12:30:55.424Z"
}
```

This one doesn't contain much information because it's quite old; it was sent from the phone I had back then (a budget Wiko Lenny) and it seems like they didn't measure as much stuff as they do now.

Here's a more recent packet:

```json
{
    "latitudeE7": 506444929,
    "longitudeE7": 30775562,
    "accuracy": 22,
    "altitude": 76,
    "verticalAccuracy": 3,
    "activity": [
        {
            "activity": [
                {
                    "type": "ON_FOOT",
                    "confidence": 80
                },
                {
                    "type": "WALKING",
                    "confidence": 80
                },
                {
                    "type": "IN_VEHICLE",
                    "confidence": 6
                },
                {
                    "type": "ON_BICYCLE",
                    "confidence": 6
                },
                {
                    "type": "IN_ROAD_VEHICLE",
                    "confidence": 6
                },
                {
                    "type": "IN_RAIL_VEHICLE",
                    "confidence": 6
                },
                {
                    "type": "RUNNING",
                    "confidence": 2
                },
                {
                    "type": "UNKNOWN",
                    "confidence": 0
                }
            ],
            "timestamp": "2024-03-21T17:42:26.290Z"
        }
    ],
    "source": "WIFI",
    "deviceTag": 123456,
    "platformType": "ANDROID",
    "activeWifiScan": {
        "accessPoints": [
            {
                "mac": "xxxxxx237234444",
                "strength": -80,
                "isConnected": true,
                "frequencyMhz": 0
            },
            {
                "mac": "xxxxxx237222816",
                "strength": -85,
                "frequencyMhz": 0
            },
            {
                "mac": "xxxxxx559068245",
                "strength": -88,
                "frequencyMhz": 0
            },
            {
                "mac": "xxxxxx759298638",
                "strength": -89,
                "frequencyMhz": 0
            }
        ]
    },
    "osLevel": 34,
    "serverTimestamp": "2024-03-21T17:44:37.220Z",
    "deviceTimestamp": "2024-03-21T17:44:38.992Z",
    "batteryCharging": false,
    "formFactor": "PHONE",
    "timestamp": "2024-03-21T17:42:29.183Z"
}
```

It only contains data processed locally on the phone. We can see it tried to guess what I was doing, and also sent a list of nearby Wi-Fi networks.

### Processed data
{: class="d-none" }

The aptly named `Semantic Location History` folder contains the Google-processed data. Notably, it contains both **place visits**, that describe places I were, and **activity segments**, that describe things I did over a period of time. Here are two packets from the same time period as the one above:

```json
{
    "placeVisit": {
        "location": {
            "latitudeE7": 506443503,
            "longitudeE7": 30774789,
            "placeId": "ChIJD-fhtSEqw0cRkCuIhwJPMx8",
            "address": "147 Rue du Ballon, 59110 La Madeleine, France",
            "name": "Nexedi",
            "semanticType": "TYPE_UNKNOWN",
            "sourceInfo": {
                "deviceTag": 850787795
            },
            "locationConfidence": 46.95392,
            "calibratedProbability": 46.95392
        },
        "duration": {
            "startTimestamp": "2024-03-20T18:36:21Z",
            "endTimestamp": "2024-03-21T17:42:24Z"
        },
        "placeConfidence": "MEDIUM_CONFIDENCE",
        "visitConfidence": 99,
        "otherCandidateLocations": [
            {
                "latitudeE7": 506442688,
                "longitudeE7": 30772597,
                "placeId": "ChIJt-gKoQwqw0cR_BiE7FjE1sM",
                "address": "34 Av. Verdi, 59110 La Madeleine, France",
                "semanticType": "TYPE_SEARCHED_ADDRESS",
                "locationConfidence": 45.081074,
                "calibratedProbability": 45.081074
            },
            {
                "latitudeE7": 506443473,
                "longitudeE7": 30774441,
                "placeId": "ChIJW0n_oQwqw0cRLSCoT36NyAY",
                "address": "147 Rue du Ballon, 59110 La Madeleine, France",
                "semanticType": "TYPE_UNKNOWN",
                "locationConfidence": 7.4105234,
                "calibratedProbability": 7.4105234
            },
            {
                "latitudeE7": 506445560,
                "longitudeE7": 30775986,
                "placeId": "ChIJy6IzmAwqw0cRyUwotTJRo8M",
                "address": "48 Av. Louise, 59110 La Madeleine, France",
                "semanticType": "TYPE_UNKNOWN",
                "locationConfidence": 0.20785488,
                "calibratedProbability": 0.20785488
            },
            "/* many others */"
        ],
        "editConfirmationStatus": "NOT_CONFIRMED",
        "locationConfidence": 47,
        "placeVisitType": "SINGLE_PLACE",
        "placeVisitImportance": "MAIN"
    }
}
{
    "activitySegment": {
        "startLocation": {
            "latitudeE7": 506452913,
            "longitudeE7": 30765453,
            "sourceInfo": {
                "deviceTag": 850787795
            }
        },
        "endLocation": {
            "latitudeE7": 506525419,
            "longitudeE7": 30805372,
            "sourceInfo": {
                "deviceTag": 850787795
            }
        },
        "duration": {
            "startTimestamp": "2024-03-21T17:42:24Z",
            "endTimestamp": "2024-03-21T17:54:24Z"
        },
        "distance": 973,
        "activityType": "WALKING",
        "confidence": "HIGH",
        "activities": [
            {
                "activityType": "WALKING",
                "probability": 97.82699942588806
            },
            {
                "activityType": "IN_TRAM",
                "probability": 0.5118888337165117
            },
            {
                "activityType": "IN_PASSENGER_VEHICLE",
                "probability": 0.27286421973258257
            },
            {
                "activityType": "CYCLING",
                "probability": 0.17150864005088806
            },
            {
                "activityType": "IN_TRAIN",
                "probability": 0.1608503283932805
            },
            {
                "activityType": "IN_SUBWAY",
                "probability": 0.10802004253491759
            },
            {
                "activityType": "IN_BUS",
                "probability": 0.08674889104440808
            },
            {
                "activityType": "RUNNING",
                "probability": 0.07946699624881148
            },
            {
                "activityType": "IN_FERRY",
                "probability": 0.04058652848470956
            },
            {
                "activityType": "SAILING",
                "probability": 0.005038841118221171
            },
            {
                "activityType": "MOTORCYCLING",
                "probability": 0.0035849196137860417
            },
            {
                "activityType": "SKIING",
                "probability": 0.0032918462238740176
            },
            {
                "activityType": "FLYING",
                "probability": 9.03989166545216E-4
            }
        ],
        "waypointPath": {
            "waypoints": [
                {
                    "latE7": 506444816,
                    "lngE7": 30776507
                },
                {
                    "latE7": 506459426,
                    "lngE7": 30749950
                },
                {
                    "latE7": 506460113,
                    "lngE7": 30750701
                },
                {
                    "latE7": 506521911,
                    "lngE7": 30811212
                },
                {
                    "latE7": 506525421,
                    "lngE7": 30805346
                }
            ],
            "source": "INFERRED",
            "roadSegment": [
                {
                    "placeId": "ChIJG9zengwqw0cRnoAeiorlC5U",
                    "duration": "8s"
                },
                {
                    "placeId": "ChIJHYTkuwwqw0cRwMDf0gLaefA",
                    "duration": "71s"
                },
                "/* many others */"
            ],
            "distanceMeters": 1175.9853099670709,
            "travelMode": "WALK",
            "confidence": 0.9999485583582982
        },
        "simplifiedRawPath": {
            "points": [
                {
                    "latE7": 506459770,
                    "lngE7": 30751483,
                    "accuracyMeters": 6,
                    "timestamp": "2024-03-21T17:45:19.542Z"
                }
            ]
        }
    }
}
```

Here, the gremlins inside Google's servers have managed to deduce from the periodic location data sent by my phone that I was at [the office](https://www.nexedi.com/) for a bit more than a day (I was sleeping in the office bedroom that week), and that I walked somewhere. Indeed, I was on my way to the [sixth edition of the Rust Lille meetup](https://www.linkedin.com/posts/zenika_rust-lille-6-du-rss-et-de-lecs-jeu-activity-7173262334382063616-tl-b/)!

## Processing it with Python

I wrote a simple [Python script](https://gist.github.com/zdimension/8bf11dd61a6e18f70ddad9f47fdecef6) that parses the JSON, aggregates the data in multiple fun ways, and outputs it to JSON files I can use as charts on this blog (try viewing the page source!).

### Measuring my walking speed

For pretty much any data set whatsoever, the most obvious measure is often the average. As a disclaimer, I filtered walks that indicated a walking speed of more than 15 km/h (I'm not *that* good of an athlete) and less than 1 km/h (I'm not *that* slow of a walker).

Binned and histogrammed, the data looks like this:

<div class="chart"><canvas id="walkSpeed"></canvas></div>

The average measured walking speed is **4.01 km/h** (median 4.03 km/h), that is, close enough to the 5 km/h figure that is often used as a rule of thumb for walking speed for an adult human. High-passing above 2 or 3 km/h (which are realistic speeds for walking) would contribute to make the average closer to 5 km/h.

The data isn't perfect by any means, we can see a long tail of fast walks on the right that we can attribute to me running to catch my bus, and a few slow walks on the left that are probably me walking around the house. And that's without accounting for the fact that the data is only from when I had my phone on me, which is true most of the time but not always. Plus, it's only what *the algorithms* have deduced from periodic position data!

### Measuring my walking distance over time

Grouping walks by month and summing the distance gives us this lovely chart that I've labelled with what I was doing at the time:

<div class="chart" style="height: 28rem"><canvas id="walkYearly"></canvas></div>

Here, I've grouped batches of 12 months by the academic year they belong to, instead of the calendar year. The rationale is that for those years, my life was mostly structured by the academic year, from September to August. 

I walked a lot in high school, a bit less in prep school, and got to an all-time low in my second year, because of the first COVID lockdown (admittedly I was also skipping a lot of classes in the end of the year) which made us attend the last 3-4 months of class from home. 

Enter third year and it goes back up a bit, well, until the next lockdown, at the end of October, but this time the whole year was done remotely. Fourth and fifth year were pretty normal, and then I started working (remotely, so I walk a lot on the evenings).

We can get a bit more granular and look at the monthly distance walked. Here I've labelled specific periods of time that explain some of the peaks and valleys:

<div class="chart" style="height: 28rem"><canvas id="walkMoving"></canvas></div>
<label>Mobile users: consider landscape mode?</label>

<script src="https://cdnjs.cloudflare.com/ajax/libs/Chart.js/4.4.1/chart.umd.min.js" integrity="sha512-CQBWl4fJHWbryGE+Pc7UAxWMUMNMWzWxF4SQo9CgkJIN1kx6djDQZjh3Y8SZ1d+6I+1zze6Z7kHXO7q3UyZAWw==" crossorigin="anonymous" referrerpolicy="no-referrer"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/chartjs-plugin-annotation/3.0.1/chartjs-plugin-annotation.min.js" integrity="sha512-Hn1w6YiiFw6p6S2lXv6yKeqTk0PLVzeCwWY9n32beuPjQ5HLcvz5l2QsP+KilEr1ws37rCTw3bZpvfvVIeTh0Q==" crossorigin="anonymous" referrerpolicy="no-referrer"></script>
<script>
    {
        const speed = {"hist": [83, 95, 136, 138, 172, 176, 219, 225, 268, 256, 292, 291, 277, 268, 213, 148, 117, 74, 42, 43, 27, 27, 16, 16, 10, 10, 13, 5, 9, 5, 8, 3, 8, 6, 4, 2, 1, 3, 5, 3, 3, 1, 5, 4, 2], "bins": [1.0011902481306194, 1.3073248682601482, 1.613459488389677, 1.9195941085192056, 2.2257287286487344, 2.531863348778263, 2.837997968907792, 3.1441325890373206, 3.4502672091668494, 3.756401829296378, 4.062536449425907, 4.368671069555436, 4.674805689684964, 4.980940309814493, 5.287074929944022, 5.593209550073551, 5.899344170203079, 6.205478790332608, 6.511613410462137, 6.817748030591666, 7.123882650721194, 7.430017270850723, 7.736151890980252, 8.042286511109781, 8.34842113123931, 8.654555751368838, 8.960690371498366, 9.266824991627896, 9.572959611757424, 9.879094231886953, 10.185228852016483, 10.491363472146011, 10.79749809227554, 11.103632712405068, 11.409767332534596, 11.715901952664126, 12.022036572793654, 12.328171192923183, 12.634305813052713, 12.940440433182241, 13.24657505331177, 13.552709673441298, 13.858844293570826, 14.164978913700356, 14.471113533829884, 14.777248153959412]};
        const ctx = document.getElementById("walkSpeed");
        const myChart = new Chart(ctx, {
            type: 'bar',
            data: {
                labels: speed.bins.map(x => x.toFixed(2)),
                datasets: [{
                    label: "Walking speed",
                    data: speed.hist,
                    backgroundColor: 'rgba(255, 99, 132, 0.4)',
                    borderColor: 'rgba(255, 99, 132, 1)',
                    borderWidth: 1
                }]
            },
            options: {
                maintainAspectRatio: false,
                scales: {
                    x: { title: { text: 'Walking speed (km/h)', display: true } },
                    y: {
                        beginAtZero: true, title: { text: 'Walk count', display: true },
                        ticks: { stepSize: 50 },
                        max: 400
                    }
                },
                layout: { padding: 20 },
                plugins: {
                    legend: { display: false },
                    title: { display: true, text: 'Walking speed distribution', font: { size: 16 }, padding: { bottom: 15 } },
                    annotation: {
                        annotations: [{
                            type: 'line',
                            scaleID: 'x',
                            value: 10,
                            mode: 'vertical',
                            borderColor: 'red',
                            borderWidth: 2,
                            label: { content: 'Average speed', display: true, position: 'start' }
                        }]
                    }
                }
            }
        });
    }
    {
        const yearly = {"2017": 402.559, "2018": 305.67999999999995, "2019": 147.011, "2020": 251.72899999999998, "2021": 435.0381344177024, "2022": 422.58804936335247, "2023": 343.313};
        const years = Object.keys(yearly);
        const names = ["HS Senior", "Prep. Y1", "Prep. Y2", "Eng. Y1", "Eng. Y2", "Eng. Y3", "Work"];
        const ctx = document.getElementById("walkYearly");
        const myChart = new Chart(ctx, {
            type: 'bar',
            data: {
                labels: years,
                datasets: [{
                    label: "Walking distance",
                    data: Object.values(yearly),
                    backgroundColor: 'rgba(75, 192, 192, 0.4)',
                    borderColor: 'rgba(75, 192, 192, 1)',
                    borderWidth: 1
                }]
            },
            options: {
                maintainAspectRatio: false,
                scales: {
                    x: { 
                        title: { text: ['Academic year', '(September to August)'], display: true },
                        ticks: { callback: function(value, index, values) { return [years[index] + "-" + (+years[index] + 1), names[index]]; } }
                    },
                    y: { 
                        title: { text: 'Distance walked (km)', display: true },
                        afterFit(scale) {
                            scale.width = 60;
                        },
                    }
                },
                layout: { padding: 20 },
                plugins: {
                    legend: { display: false },
                    title: { display: true, text: 'Walking distance per academic year', font: { size: 16 }, padding: { bottom: 15 } },
                    annotation: {
                        annotations: [
                            {
                                type: 'line',
                                scaleID: 'x',
                                value: 2.1,
                                mode: 'vertical',
                                borderColor: 'red',
                                borderWidth: 2,
                                label: { content: 'COVID lockdown #1', display: true, position: 'start', z: 10 }
                            }, {
                                type: 'line',
                                scaleID: 'x',
                                value: 2.8,
                                mode: 'vertical',
                                borderColor: 'red',
                                borderWidth: 2,
                                label: { content: 'COVID lockdown #2', display: true, position: '20%' }
                            }
                        ]
                    }
                }
            }
        });
    }
    {
        const monthly = {
            "2017-09": parseFloat("NaN"),
            "2017-10": 47.895500000000006, "2017-11": 50.757000000000005, "2017-12": 43.405499999999996, "2018-01": 30.753750000000004, "2018-02": 25.093, "2018-03": 25.428250000000002, "2018-04": 29.12525, "2018-05": 32.8595, "2018-06": 31.246000000000002, "2018-07": 25.0345, "2018-08": 26.0245, "2018-09": 36.112500000000004, "2018-10": 42.70425, "2018-11": 41.093500000000006, "2018-12": 33.7465, "2019-01": 32.87650000000001, "2019-02": 34.63, "2019-03": 26.487000000000002, "2019-04": 16.407750000000004, "2019-05": 11.581000000000003, "2019-06": 11.7455, "2019-07": 11.466999999999999, "2019-08": 14.3705, "2019-09": 22.593000000000004, "2019-10": 24.332500000000007, "2019-11": 20.120500000000003, "2019-12": 16.80275, "2020-01": 15.683499999999999, "2020-02": 12.82375, "2020-03": 7.08425, "2020-04": 3.582, "2020-05": 3.42725, "2020-06": 4.785, "2020-07": 5.94425, "2020-08": 11.535250000000001, "2020-09": 21.4435, "2020-10": 19.54925, "2020-11": 8.86275, "2020-12": 6.60525, "2021-01": 8.996249999999998, "2021-02": 9.3685, "2021-03": 9.21975, "2021-04": 10.597000000000001, "2021-05": 26.8715, "2021-06": 48.64625, "2021-07": 39.95125, "2021-08": 25.93925, "2021-09": 36.282250000000005, "2021-10": 39.056, "2021-11": 30.910749999999997, "2021-12": 29.586, "2022-01": 33.71225, "2022-02": 40.059000000000005, "2022-03": 43.938, "2022-04": 42.300749999999994, "2022-05": 38.108, "2022-06": 29.903, "2022-07": 22.2015336044256, "2022-08": 35.6613172088512, "2022-09": 55.21522051453416, "2022-10": 51.35312382021712, "2022-11": 36.80743691010856, "2022-12": 35.54825, "2023-01": 38.27707543072957, "2023-02": 29.786150861459127, "2023-03": 28.294075430729563, "2023-04": 36.75675, "2023-05": 38.94200000000001, "2023-06": 37.717000000000006, "2023-07": 34.3695, "2023-08": 27.584749999999996, "2023-09": 25.537999999999997, "2023-10": 24.507999999999996, "2023-11": 19.972, "2023-12": 20.9315, "2024-01": 23.556749999999997, "2024-02": 24.250999999999998, "2024-03": 36.6345, "2024-04": 55.308, "2024-05": 64.283,
            "2024-06": parseFloat("NaN"),
            "2024-07": parseFloat("NaN"),
            "2024-08": parseFloat("NaN"),
            "2024-09": parseFloat("NaN"),
        };
        const monthIds = Object.keys(monthly);
        function toId(date) {
            const [y, m, d] = date.split("-");
            // find id in monthIds
            const monthId = monthIds.indexOf(`${y}-${m}`);
            const daysInMonth = new Date(y, m, 0).getDate();
            return monthId + parseFloat(d - 1) / daysInMonth - 0.5;
        }
        const ctx = document.getElementById("walkMoving");
        const shouldDash = (context) => {
            return context.tick && context.index !== 0 && context.index !== monthIds.length - 1 &&
                context.tick.label.endsWith("-09");
        };
        const myChart = new Chart(ctx, {
            type: 'line',
            data: {
                labels: monthIds,
                datasets: [{
                    label: "Walking distance",
                    data: Object.values(monthly),
                    backgroundColor: 'rgba(54, 162, 235, 0.4)',
                    borderColor: 'rgba(54, 162, 235, 1)',
                    borderWidth: 1,
                    fill: true
                }]
            },
            options: {
                maintainAspectRatio: false,
                scales: {
                    x: { 
                        title: { text: ['Month', '(3-month moving average)'], display: true },
                        border: {
                            dash: (context) => {
                                return shouldDash(context) ? [5, 5] : undefined;
                            }
                        },
                        grid: {
                            color: (context) => {
                                return shouldDash(context) ? 'rgb(0,0,0,0.5)' : undefined;
                            },
                            offset: false
                        }
                    },
                    y: { 
                        title: { text: 'Distance walked (km)', display: true }, 
                        afterFit(scale) {
                            scale.width = 60;
                        },
                        max: 80
                    }
                },
                layout: { padding: 20 },
                plugins: {
                    legend: { display: false },
                    title: { display: true, text: 'Walking distance per month', font: { size: 16 }, padding: { bottom: 15 } },
                    // dashed line at each september
                    annotation: {
                        annotations: [
                            {
                                type: 'box',
                                backgroundColor: 'rgba(0,0,0,0.1)',
                                borderWidth: 0,
                                xMin: toId("2020-03-17"),
                                xMax: toId("2020-05-11"),
                                label: { 
                                    content: ['COVID', 'lockdown #1'], display: true,
                                    position: { x: 'center', y: 'start' }, textAlign: 'center', textStrokeColor: 'black', textStrokeWidth: 3, color: 'white'
                                }
                            },
                            {
                                type: 'box',
                                backgroundColor: 'rgba(0,0,0,0.1)',
                                borderWidth: 0,
                                xMin: toId("2020-10-31"),
                                xMax: toId("2021-05-01"),
                                label: { 
                                    content: ['COVID', 'lockdown #2'], display: true,
                                    position: { x: 'center', y: 'start' }, textAlign: 'center', textStrokeColor: 'black', textStrokeWidth: 3, color: 'white'
                                }
                            },
                            {
                                type: 'box',
                                backgroundColor: 'rgba(115, 214, 115, 0.3)',
                                borderWidth: 0,
                                xMin: toId("2022-05-16"),
                                xMax: toId("2022-07-31"),
                                label: { 
                                    content: ['Internship', '(remote)'], display: true, 
                                    position: { x: 'center', y: 'start' }, textAlign: 'center', textStrokeColor: 'black', textStrokeWidth: 3, color: 'white'
                                }
                            },
                            {
                                type: 'box',
                                backgroundColor: 'rgba(214, 115, 115,0.2)',
                                borderWidth: 0,
                                xMin: toId("2023-04-01"),
                                xMax: toId("2023-06-15"),
                                label: { 
                                    content: ['Went to', 'protests'], display: true, 
                                    position: { x: 'center', y: 'start' }, textAlign: 'center', textStrokeColor: 'black', textStrokeWidth: 3, color: 'white'
                                }
                            },
                            {
                                type: 'box',
                                backgroundColor: 'rgba(115, 214, 115, 0.3)',
                                borderWidth: 0,
                                xMin: toId("2019-05-15"),
                                xMax: toId("2019-07-31"),
                                label: { 
                                    content: ['Internship'], display: true, 
                                    position: { x: 'center', y: 'start' }, textAlign: 'center', textStrokeColor: 'black', textStrokeWidth: 3, color: 'white'
                                }
                            },
                            {
                                type: 'box',
                                backgroundColor: 'rgba(192, 50, 192, 0.3)',
                                borderWidth: 0,
                                xMin: toId("2024-03-14"),
                                xMax: toId("2024-06-01"),
                                label: { 
                                    content: ['Started going', 'on walks'], display: true, 
                                    position: { x: 'center', y: 'start' }, textAlign: 'center', textStrokeColor: 'black', textStrokeWidth: 3, color: 'white'
                                }
                            },
                        ]
                    }
                }
            }
        });
    }


</script>