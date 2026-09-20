typedef ViolationCallback = void Function(String eventType, String details);

void enableAssessmentSecurity({ViolationCallback? onViolation}) {}
void disableAssessmentSecurity() {}
void requestHTMLFullscreen() {}
void exitHTMLFullscreen() {}
