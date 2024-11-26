---
title: Stop using global variables in extensions
#img_path: '/assets/posts/2023-08-15-stop-using-global-variables-in-extensions/'
date_published: 2023-08-15T10:00:48.000Z
date_updated: 2023-08-15T10:00:48.000Z
tags: [Ramblings]
description: "Global state is bad and breaks websites. Kids, don't store things globally."
---

[Adfly Skipper](https://chrome.google.com/webstore/detail/adfly-skipper/obnfifcganohemahpomajbhocfkdgmjb) defines a property on `window`, called `source`. It's only used for internal purposes.

[France's IRS](https://www.impots.gouv.fr/accueil), in its decade-old authentication code, stores information in `window.source`.

I've been using Private Browsing to file my taxes for years because I couldn't get that website to work, but I finally took the time to bisect my installed extensions and debug the site. If you're French and _impots.gouv.fr_ doesn't work, try uninstalling _AdFly Skipper_.

> This post paid for by the No Global State gang.
