String fmtDuration(double seconds) {
  final t = seconds.round();
  final h = t ~/ 3600;
  final m = (t % 3600) ~/ 60;
  final s = t % 60;
  if (h > 0) return '${h}h ${m}m';
  if (m > 0) return '${m}m ${s}s';
  return '${s}s';
}

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

String fmtDate(DateTime d) {
  final l = d.toLocal();
  final h12 = l.hour % 12 == 0 ? 12 : l.hour % 12;
  final mm = l.minute.toString().padLeft(2, '0');
  final ampm = l.hour >= 12 ? 'PM' : 'AM';
  return '${_months[l.month - 1]} ${l.day}, ${l.year} - $h12:$mm $ampm';
}

final usernameRe = RegExp(r'^[A-Za-z0-9_]{3,20}$');
