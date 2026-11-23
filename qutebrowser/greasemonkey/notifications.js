// ==UserScript==
// @name         Notifications allowed on load
// @description  qutebrowser grants notifications (content.notifications.enabled)
//               only when a page asks, and forgets it on the next load: sites
//               like Discord, seeing "default", never ask and stay silent.
//               So ask for them as the page loads.
// @match        https://discord.com/*
// @run-at       document-start
// @qute-js-world main
// ==/UserScript==

if (Notification.permission === "default") {
  Notification.requestPermission();
}
