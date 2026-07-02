# Application version
module AppVersion
  VERSION = "1.0.7"
  BUILD_DATE = "2026-04-22"
  
  def self.full_version
    "v#{VERSION} (#{BUILD_DATE})"
  end
end
