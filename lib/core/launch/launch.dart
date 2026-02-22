/// Launch Module
///
/// Exports all launch-related services and widgets for Phase G.
library;

// Core launch service
export 'launch_service.dart';
export 'feedback_service.dart';
export 'early_access_banner.dart';

// A. Build Prep
export 'launch_build_service.dart';

// B. Internal Alpha
export 'internal_alpha_service.dart';
export 'alpha_invite_widget.dart';

// C. Closed Beta
export 'closed_beta_service.dart';
export 'beta_feedback_form.dart';

// E. Launch Checklist
export 'launch_checklist_service.dart';
export 'launch_readiness_report.dart';

// F. Public Launch Prep - Marketing
export 'launch_marketing_service.dart';
export 'launch_countdown_widget.dart';

// G. Post-Launch Feedback
// Hide types that conflict with feedback_service.dart
export 'post_launch_service.dart'
    hide FeedbackStatus, FeedbackCategory, FeedbackSubmissionResult;


