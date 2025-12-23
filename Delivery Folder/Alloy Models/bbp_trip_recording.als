module bbp_trip_recording
open util/boolean


abstract sig User {
  userId: one Int
}

sig RegisteredUser extends User {
  userName: one String,
  email: one String,
  passwordHash: one String
}

sig UnregisteredUser extends User {
  sessionId: one String
}

sig Trip {
  tripId: one Int,
  state: one TripState,
  startTime: one Int, 
  endTime: one Int,
  distance: one Int,      
  duration: one Int,      
  avgSpeed: one Int,      
  maxSpeed: one Int,      
  elevationGain: one Int, 
  weather: lone WeatherData
}

-- TripState represents the trip recording lifecycle
abstract sig TripState {}
one sig TripCreated, TripRecording, TripPaused, TripCompleted, TripProcessing,
TripProcessed, TripSaved, TripSavedEnriched extends TripState {}

sig WeatherData {
  temperature: one Int,
  humidity: one Int,
  windSpeed: one Int,
  precipitation: one Int,
  conditions: one String,
  fetchedAt: one Int
}

sig BikePath {
  pathId: one Int,
  createdBy: one RegisteredUser,
  createdAt: lone Int,
  currentStatus: one PathStatus, 
  obstacles: set Obstacle
}

abstract sig PathStatus {}
one sig Optimal, Medium, Sufficient, RequiresMaintenance extends PathStatus {}

sig Obstacle {
  obstacleId: one Int,
  type: one ObstacleType,
  location: one String,
  reportedBy: one RegisteredUser 
}

abstract sig ObstacleType {}
one sig Pothole, Construction, Debris, Infrastructure extends ObstacleType {}

sig PathInformation {
  pathId: one Int,
  path: one BikePath,
  trip: some Trip,
  submittedBy: one RegisteredUser,
  creationType: one CreationType,
  state: one PublicationState
}

abstract sig CreationType {}
one sig ManualEntry, AutomaticEntry extends CreationType {}

abstract sig PublicationState {}
one sig Private, Public extends PublicationState {}

-- ===== CONSTRAINTS AND FACTS =====

-- Fact: Obstacles must be reported by a RegisteredUser
fact ObstaclesHaveReporters {
  all o: Obstacle | some o.reportedBy
}

-- Fact: Obstacles must belong to a Path
fact ObstaclesBelongToPaths {
  all o: Obstacle | one bp: BikePath | o in bp.obstacles
}

-- Fact: Consistent Trip Data
fact TripNumericValuesConsistency {
  all t: Trip {
	  t.distance > 0
    t.duration > 0
    t.avgSpeed >= 0
    t.maxSpeed >= t.avgSpeed
    t.endTime > t.startTime
  }
}


-- ===== ASSERTIONS =====

-- Assert 1: Check that every obstacle has a location and reporter
assert ObstaclesHaveData {
  all o: Obstacle | some o.location and some o.reportedBy
}
check ObstaclesHaveData for 10 but 6 Int

-- Assert 2: Saved Trips Have Valid Statistics
assert SavedTripsHaveStats {
  all t: Trip |
    (t.state = TripSaved) => (t.distance > 0 and t.duration > 0 and t.avgSpeed >= 0)
}
check SavedTripsHaveStats for 10

-- Assert 3: Weather Is Optional But Consistent (review later)
assert WeatherConsistency {
  all t: Trip |
    (t.state in TripSavedEnriched) => (t.weather = WeatherData)
}
check WeatherConsistency for 10
