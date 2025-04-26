// import 'package:flutter/material.dart';
// import 'package:flutter/scheduler.dart';

// class AppLoader {
//   // Standard circular loader
//   static Widget circular({
//     Color? color,
//     double size = 24,
//     double strokeWidth = 3.0,
//   }) {
//     return SizedBox(
//       width: size,
//       height: size,
//       child: CircularProgressIndicator(
//         valueColor: AlwaysStoppedAnimation<Color>(color ?? Colors.green),
//         strokeWidth: strokeWidth,
//       ),
//     );
//   }

//   // Pulse animation loader
//   static Widget pulse({
//     Color? color,
//     double size = 24,
//   }) {
//     return SizedBox(
//       width: size,
//       height: size,
//       child: Icon(
//         Icons.pulse_loader, // You'll need to add this icon to your project
//         color: color ?? Colors.green,
//         size: size,
//       ),
//     );
//   }

//   // Skeleton loading shimmer
//   static Widget shimmer({
//     double width = double.infinity,
//     double height = 16,
//     BorderRadius borderRadius = BorderRadius.zero,
//   }) {
//     return ShimmerLoader(
//       width: width,
//       height: height,
//       borderRadius: borderRadius,
//     );
//   }

//   // Full screen loader with optional message
//   static Widget fullScreen({
//     String? message,
//     Color backgroundColor = Colors.white,
//     Color loaderColor = Colors.green,
//   }) {
//     return Container(
//       color: backgroundColor.withOpacity(0.85),
//       child: Center(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             circular(color: loaderColor, size: 48),
//             if (message != null) ...[
//               const SizedBox(height: 16),
//               Text(
//                 message,
//                 style: TextStyle(
//                   color: Colors.grey[700],
//                   fontSize: 16,
//                 ),
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }

//   // Button loader - for loading states in buttons
//   static Widget buttonLoader({
//     Color color = Colors.white,
//     double size = 20,
//   }) {
//     return SizedBox(
//       width: size,
//       height: size,
//       child: CircularProgressIndicator(
//         valueColor: AlwaysStoppedAnimation<Color>(color),
//         strokeWidth: 2.5,
//       ),
//     );
//   }

//   // Overlay loader - shows on top of existing UI
//   static void showOverlay(BuildContext context, {String? message}) {
//     final overlay = Overlay.of(context);
//     final overlayEntry = OverlayEntry(
//       builder: (context) => Positioned.fill(
//         child: Material(
//           color: Colors.black.withOpacity(0.4),
//           child: Center(
//             child: Container(
//               padding: const EdgeInsets.all(24),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   circular(size: 36),
//                   if (message != null) ...[
//                     const SizedBox(height: 16),
//                     Text(
//                       message,
//                       style: const TextStyle(fontSize: 16),
//                     ),
//                   ],
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );

//     overlay.insert(overlayEntry);

//     // Auto-remove after 30 seconds if not removed manually
//     Future.delayed(const Duration(seconds: 30)).then((_) {
//       if (overlayEntry.mounted) {
//         overlayEntry.remove();
//       }
//     });

//     return overlayEntry;
//   }

//   static void hideOverlay(OverlayEntry? overlayEntry) {
//     if (overlayEntry != null && overlayEntry.mounted) {
//       overlayEntry.remove();
//     }
//   }
// }

// // Shimmer loading widget
// class ShimmerLoader