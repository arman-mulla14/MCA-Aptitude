import 'dart:js' as js;

typedef ViolationCallback = void Function(String eventType, String details);

void enableAssessmentSecurity({ViolationCallback? onViolation}) {
  try {
    if (onViolation != null) {
      js.context['onAssessmentSecurityViolation'] = js.allowInterop((eventType, details) {
        onViolation(eventType.toString(), details.toString());
      });
    }
    js.context.callMethod('enableAssessmentSecurity');
  } catch (e) {
    // Ignore if not in browser or function not available
  }
}

void disableAssessmentSecurity() {
  try {
    js.context['onAssessmentSecurityViolation'] = null;
    js.context.callMethod('disableAssessmentSecurity');
  } catch (e) {
    // Ignore
  }
}

void requestHTMLFullscreen() {
  try {
    js.context.callMethod('requestHTMLFullscreen');
  } catch (e) {}
}

void exitHTMLFullscreen() {
  try {
    js.context.callMethod('exitHTMLFullscreen');
  } catch (e) {}
}
