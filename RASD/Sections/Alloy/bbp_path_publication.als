module bbp_path_publication


-- == Signatures ==

-- Actors --
abstract sig User {}
sig RegisteredUser extends User {}
sig UnregisteredUser extends User {}

-- Paths --
sig BikePath {
	obstacles: set PathObstacle
}

-- Path contribution modes
abstract sig PathCreationMode {}
one sig ManualMode, AutomaticMode extends PathCreationMode {}

-- Review status
abstract sig PathReviewStatus {}
one sig Unreviewed, Reviewed extends PathReviewStatus {}

-- Publication status
abstract sig PathPublicationStatus {}
one sig Private, Public extends PathPublicationStatus {}

-- Optional obstacle abstraction
abstract sig PathObstacle {}
one sig Pothole, Construction, Debris, Infrastructure extends PathObstacle {}

-- Path information contributed by users
sig PathInformation {
	path: one BikePath,
	submittedBy: one RegisteredUser,
	creationMode: one PathCreationMode,
	reviewStatus: one PathReviewStatus,
	publicationStatus: one PathPublicationStatus
}


-- == Key Facts ==

-- Fact 1: Only registered users can submit path information
fact OnlyRegisteredUsersSubmit {
  all pi: PathInformation | pi.submittedBy in RegisteredUser
}

-- Fact 2: Manually created paths is considered reviewed by default
fact AllManualPathsAreReviewed {
  all pi: PathInformation |
    pi.creationMode = ManualMode => pi.reviewStatus = Reviewed
}

-- Fact 3: Automatically registered data must be reviewed before publication
fact AutomaticEntriesNeedReviewBeforePublish {
  all pi: PathInformation |
    (pi.creationMode = AutomaticMode and pi.publicationStatus = Public)
      => pi.reviewStatus = Reviewed
}

-- Function that returns all public paths or submitted by a specific user
fun visiblePathInformation[u: User]: set PathInformation {
  { pi: PathInformation |
      pi.publicationStatus = Public
      or pi.submittedBy = u
  }
}


-- == Assertions ==

-- Assertion 1: No automatically acquired, unreviewed path information is publicly visible
assert NoUnreviewedAutomaticPublic {
  no pi: PathInformation |
    pi.creationMode = AutomaticMode
    and pi.reviewStatus = Unreviewed
    and pi.publicationStatus = Public
}
check NoUnreviewedAutomaticPublic for 10

-- Assertion 2: Any publicly visible path information has been reviewed beforehand
assert PublishedOnlyIfReviewed {
  all pi: PathInformation |
    pi.publicationStatus = Public => pi.reviewStatus = Reviewed
}
check PublishedOnlyIfReviewed for 10

-- Assertion 3: Manual path information is recognized as reviewed by default
assert ManualAlwaysReviewed {
  all pi: PathInformation |
    pi.creationMode = ManualMode => pi.reviewStatus = Reviewed
}
check ManualAlwaysReviewed for 10

-- Assertion 4: Unregistered users never see private path information
assert UnregisteredUsersSeeOnlyPublic {
  all u: UnregisteredUser |
    all pi: PathInformation |
      pi in visiblePathInformation[u] =>
        pi.publicationStatus = Public
}
check UnregisteredUsersSeeOnlyPublic for 20

-- Assertion 5: Registered users are able to see their own private path information
assert OwnersCanSeePrivatePaths {
  all u: RegisteredUser |
    all pi: PathInformation |
      (pi.submittedBy = u) =>
        pi in visiblePathInformation[u]
}
check OwnersCanSeePrivatePaths for 20


-- == Run Command ==

pred manualPublicExample {
  some pi: PathInformation |
    pi.creationMode = ManualMode
    and pi.reviewStatus = Reviewed
    and pi.publicationStatus = Public
}
run manualPublicExample for 6


pred automaticPendingReview {
  some pi: PathInformation |
    pi.creationMode = AutomaticMode
    and pi.reviewStatus = Unreviewed
    and pi.publicationStatus = Private
}
run automaticPendingReview for 10 but 1 ManualMode


pred visibilityExample {
  some u1: RegisteredUser, u2: UnregisteredUser, pi: PathInformation |
    pi.creationMode = AutomaticMode
    and pi.reviewStatus = Unreviewed
    and pi.publicationStatus = Private
    and pi.submittedBy = u1
    and pi in visiblePathInformation[u1]
    and pi not in visiblePathInformation[u2]
}
run visibilityExample for 4
