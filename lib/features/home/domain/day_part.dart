/// Which greeting Home's header shows, from the device's local hour.
enum DayPart { morning, afternoon, evening }

DayPart dayPartFor(int hour) {
  if (hour >= 5 && hour < 12) return DayPart.morning;
  if (hour >= 12 && hour < 17) return DayPart.afternoon;
  return DayPart.evening;
}
