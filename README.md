<h1 align="center">
  <img src="assets/logo_placeholder.png" alt="The Radical Logo" width="128" height="128"/>
  <br>
  The Radical
</h1>

<p align="center">
  A high-performance news aggregator centralized for Australian political and social perspectives — built for rapid information scanning and independent media discovery.
</p>

<div align="center">

<a href="https://spacemansparrow.github.io/LeftNewsGrabberProject/">
  <img src="https://img.shields.io/badge/Live_Demo-Visit_The_Radical-red?style=for-the-badge&logo=rocket" alt="Live Site">
</a>

</div>

-----

> [!IMPORTANT]
> **Beta Disclaimer:** The Radical is currently in active development. As a centralized hub for independent media, it relies on direct RSS/Atom feeds. You may encounter incomplete metadata as we refine our custom regex-based parsing engines.

-----

## 📸 Screenshots

<table align="center"><tr>
<td align="center"><img src="https://via.placeholder.com/400x225?text=Dashboard+Main+View" alt="Dashboard View" width="100%"/><br><em>Main Feed Aggregator</em></td>
<td align="center"><img src="https://via.placeholder.com/400x225?text=Topic+Filtering+UI" alt="Topic Filtering" width="100%"/><br><em>Topic Filtering System</em></td>
</tr><tr>
<td align="center"><img src="https://via.placeholder.com/400x225?text=Custom+Themes+Gallery" alt="Themes" width="100%"/><br><em>Theme Gallery (Amber/Rose/Emerald)</em></td>
<td align="center"><img src="https://via.placeholder.com/400x225?text=Mobile+Responsive+View" alt="Mobile View" width="100%"/><br><em>Responsive Web Design</em></td>
</tr></table>

-----

## 💡 Motivation

The Radical was born out of a need to centralize news from leftist and independent perspectives without the friction of checking dozens of separate websites. In the current media landscape, independent voices are often scattered; this dashboard brings them into a single, cohesive interface.

**Learning Journey:**
This project serves as my primary vehicle for learning **Flutter**. While I utilize AI to assist in complex architecture and debugging, the goal is to create a functional tool that serves the community while I refine my skills as a developer.

-----

## ✨ Features

### Content Management

| Feature | Description | Source/Tech |
| :--- | :--- | :--- |
| **Real-time Aggregation** | Direct fetching from 15+ independent sources via CORS proxying. | `Custom Regex Parser` |
| **Topic Classification** | Automatic sorting into Economy, Labour, First Nations, and more. | `Keyword Matching Logic` |
| **Media Proxying** | Optimized image delivery and CORS handling for web browsers. | `weserv.nl Proxy` |

### UI & Personalization

| Feature | Description | Requirements |
| :--- | :--- | :--- |
| **Persistent Themes** | Choice of 6 high-contrast palettes saved to local device storage. | `SharedPreferences` |
| **Typography** | Optimized for readability using Space Grotesk and Manrope. | `Google Fonts` |
| **Responsive Grid** | Adaptive layout that shifts from 1 to 3 columns based on width. | `MediaQuery / GridView` |

-----

## 🛠 Tech Stack

* **Framework:** [Flutter](https://flutter.dev) (Web target)
* **Data Handling:** Custom RSS/Atom XML engine (zero-dependency parsing)
* **Networking:** [http](https://pub.dev/packages/http) with [CORS Proxy](https://corsproxy.io/)
* **Storage:** [shared_preferences](https://pub.dev/packages/shared_preferences) for user settings
* **Icons:** [Font Awesome Flutter](https://pub.dev/packages/font_awesome_flutter)
* **Fonts:** Space Grotesk & Manrope via [Google Fonts](https://fonts.google.com/)

-----

## 🚀 Roadmap & Known Issues

### Currently Working On

- [ ] **Enhanced Image Scraping:** Improving regex patterns to catch obscure `<media:content>` and OpenGraph tags.
- [ ] **Extended Source List:** Integrating additional regional independent Australian publishers.
- [ ] **Article Search:** Refining the real-time filter for body text and headlines.

### Known Bugs

- Some RSS feeds return non-standard date formats, occasionally defaulting to "Recent".
- Large XML payloads can cause a brief UI stutter on initial parse in lower-end browsers.

-----
