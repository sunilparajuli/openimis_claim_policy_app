# Java source alignment

Reference check: 2026-10-09, local copies under `/tmp/openimis_java_repos`.

## Home summaries

The original apps do contain dashboards:

- Claims: `claimManagement/src/main/res/layout/content_main.xml` and `MainActivity.java` show **Dashboard**, **Accepted**, **Rejected**, **Pending**. Counts come from synchronization broadcasts.
- Policies: `app/src/main/res/layout/home_content.xml` shows **Total Families**, **Edited Families**, **Total Insurees**, **Edited Insurees**, **Total Policies**, **Total Contributions**, **Total Amount**.

Flutter now uses those labels. It displays an unavailable marker instead of fabricated counts because synchronization/policy totals are not connected. The local offline queue count remains separate from server claim status totals.

Removed invented approval percentages, fiscal-year premium totals, fictional doctor/facility identity, and the template Explore/Profile bottom navigation. Reports and Check Commission remain because they exist in the Java app.

## Permissions

Checked both Android manifests, both `Global.java` permission arrays, and the Policies `Acquire.java` location checks.

| Capability | Flutter implementation |
| --- | --- |
| Camera | Android declaration and runtime request; iOS camera usage description and native request |
| Insuree photos | Android image-library permission (legacy read storage through API 32; selected-photo access on API 34+); iOS read/write photo-library authorization, including limited access |
| Foreground location | Android coarse/fine location request; iOS when-in-use authorization |
| Network/Wi-Fi state and vibration | Android manifest declarations; no runtime consent dialogs required |

Requests are explicit in **Settings → Permissions**, with permission status, denied/limited states and a device-settings link. Returning from system settings refreshes status. Permission grants do not themselves implement photo capture, QR scanning, or enrolment location acquisition.

The Policies Java manifest removes contacts, call logs and broad file-management permissions. These are not added to Flutter. Video/audio library access, package installation and Wi-Fi modification workflows are not implemented in Flutter; no corresponding runtime prompts are added. Background location and microphone access are not requested.

Android media-access reference: https://developer.android.com/training/data-storage/shared/media

Native changes require an application rebuild; hot reload alone cannot update AndroidManifest.xml or Info.plist.

## Remaining parity limitations

This change aligns home content and permission support, not all business workflows. Existing demo data in other features, incomplete individual insuree enrolment, policy/contribution subforms and payment/control-number flows still require implementation. Dashboard totals must be connected to the appropriate data sources before they can show real values.
