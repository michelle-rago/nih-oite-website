class Event
  include NetlifyContent

  def self.all(after: nil, base: Rails.root.join("_events"))
    after ||= Date.today

    events = super base: base

    events.select { |event| event.date >= after }.sort_by(&:date)
  end

  def self.audiences(file = Rails.root.join("_settings/audiences.yml"))
    data = YAML.safe_load File.read(file), fallback: {}
    data["audiences"] || []
  end

  def self.topics(file = Rails.root.join("_settings/topics.yml"))
    data = YAML.safe_load File.read(file), fallback: {}
    data["topics"] || []
  end

  def self.find_by_path(path, base: Rails.root.join("_events"), try_index: false)
    super path, base: base, try_index: try_index
  end

  attr_reader :filename
  has_field :title
  has_field :speakers, :audience, default: []
  has_field :accommodations, default: {}
  has_field :topic, default: []

  def initialize(path, base: nil)
    @filename = path.basename(".md")
    @parsed_file = FrontMatterParser::Parser.parse_file(path, loader: yaml_loader)
  end

  def to_param
    filename
  end

  def date
    @date ||= begin
      d = parsed_file["date"]
      Date.new(d["year"], d["month"], d["day"])
    end
  end

  def start
    date_with_time start_time
  end

  def end
    date_with_time end_time
  end

  def start_time
    parsed_file["start"].downcase
  end

  def end_time
    parsed_file["end"].downcase
  end

  def speaker_names
    speakers.map { |speaker| speaker["name"] }
  end

  def accommodations_poc
    accommodations["name"]
  end

  def accommodations_email
    accommodations["email"]
  end

  def accommodations_phone
    accommodations["phone"]
  end

  private

  def date_with_time(time)
    m = /^(\d+):(\d+)\s*(am|pm)$/i.match time

    hour = m[1].to_i
    minute = m[2].to_i
    ampm = m[3].downcase

    hour += 12 if ampm == "pm" && hour < 12

    Time.new(
      date.year,
      date.month,
      date.day,
      hour,
      minute
    )
  end
end
