/// Permission levels used by the security layer.
///
/// These levels describe *who* is allowed to perform an operation, as opposed
/// to `PermissionLevel` in `automation/action_registry.dart`, which describes
/// *how far* an action may be automated.
library;

/// Levels of trust for an operation, ordered from least to most privileged.
enum SecurityPermissionLevel {
  /// No access at all.
  none,

  /// Regular end user of the host application.
  user,

  /// A trusted service running inside the host application.
  trustedService,

  /// Administrative access.
  admin,

  /// Full system access (SDK internals only).
  system,
}
