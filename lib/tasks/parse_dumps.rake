# frozen_string_literal: true

#
# Determine if string is an integer in quotes
# <https://stackoverflow.com/a/1235891>
#
class String
  def integer?
    [                          # In descending order of likeliness:
      /^[-+]?[1-9]([0-9]*)?$/, # decimal
      /^0[0-7]+$/,             # octal
      /^0x[0-9A-Fa-f]+$/,      # hexadecimal
      /^0b[01]+$/              # binary
    ].each do |match_pattern|
      return true if self =~ match_pattern
    end
  end
end

#
# SAX parser for nations.xml
# Creates an array of hashes of nation data and passes to activerecord-import
#
class NationParser < Nokogiri::XML::SAX::Document
  def initialize
    super
    @nations = []
    reset_state
  end

  #
  # Reset state when starting a new nation
  #
  def reset_state
    @current_nation = {}
    @state = Constants::NationCollectors::COLLECT_NOTHING
    @current_name = ''
    @current_type = ''
    @current_fullname = ''
    @current_motto = ''
    @current_category = ''
    @current_unstatus = ''
    @current_endorsements = []
    @current_issues_answered = 0
    @current_freedom_civilrights = ''
    @current_freedom_economy = ''
    @current_freedom_politicalfreedom = ''
    @current_region = ''
    @current_population = 0
    @current_tax = 0
    @current_animal = ''
    @current_currency = ''
    @current_demonym = ''
    @current_demonym2 = ''
    @current_demonym2plural = ''
    @current_flag = ''
    @current_majorindustry = ''
    @current_govtpriority = ''
    @current_administration = 0
    @current_defence = 0
    @current_education = 0
    @current_environment = 0
    @current_healthcare = 0
    @current_commerce = 0
    @current_internationalaid = 0
    @current_lawandorder = 0
    @current_publictransport = 0
    @current_socialequality = 0
    @current_spirituality = 0
    @current_welfare = 0
    @current_founded = ''
    @current_firstlogin = 0
    @current_lastlogin = 0
    @current_lastactivity = ''
    @current_influence = ''
    @current_freedomscores_civilrights = 0
    @current_freedomscores_economy = 0
    @current_freedomscores_politicalfreedom = 0
    @current_publicsector = 0
    @current_death_cause = {
      cause: '',
      value: 0
    }
    @current_deaths = []
    @current_leader = ''
    @current_capital = ''
    @current_religion = ''
    @current_factbooks = 0
    @current_dispatches = 0
    @current_dbid = 0
  end

  #
  # Collect data from the current element and set the state
  #
  # @param [String] name Element name
  # @param [Array] attrs Element attributes
  #
  # @return [String] Collector state
  #
  def start_element(name, attrs = [])
    attrs = attrs.to_h
    @state = case name
             when 'NAME' then Constants::NationCollectors::COLLECT_NAME
             when 'TYPE' then Constants::NationCollectors::COLLECT_TYPE
             when 'FULLNAME' then Constants::NationCollectors::COLLECT_FULLNAME
             when 'MOTTO' then Constants::NationCollectors::COLLECT_MOTTO
             when 'CATEGORY' then Constants::NationCollectors::COLLECT_CATEGORY
             when 'UNSTATUS' then Constants::NationCollectors::COLLECT_UNSTATUS
             when 'ENDORSEMENTS' then Constants::NationCollectors::COLLECT_ENDORSEMENTS
             when 'ISSUES_ANSWERED' then Constants::NationCollectors::COLLECT_ISSUES_ANSWERED
             when 'CIVILRIGHTS' then Constants::NationCollectors::COLLECT_CIVILRIGHTS
             when 'ECONOMY' then Constants::NationCollectors::COLLECT_ECONOMY
             when 'POLITICALFREEDOM' then Constants::NationCollectors::COLLECT_POLITICALFREEDOM
             when 'REGION' then Constants::NationCollectors::COLLECT_REGION
             when 'POPULATION' then Constants::NationCollectors::COLLECT_POPULATION
             when 'TAX' then Constants::NationCollectors::COLLECT_TAX
             when 'ANIMAL' then Constants::NationCollectors::COLLECT_ANIMAL
             when 'CURRENCY' then Constants::NationCollectors::COLLECT_CURRENCY
             when 'DEMONYM' then Constants::NationCollectors::COLLECT_DEMONYM
             when 'DEMONYM2' then Constants::NationCollectors::COLLECT_DEMONYM2
             when 'DEMONYM2PLURAL' then Constants::NationCollectors::COLLECT_DEMONYM2PLURAL
             when 'FLAG' then Constants::NationCollectors::COLLECT_FLAG
             when 'MAJORINDUSTRY' then Constants::NationCollectors::COLLECT_MAJORINDUSTRY
             when 'GOVTPRIORITY' then Constants::NationCollectors::COLLECT_GOVTPRIORITY
             when 'ADMINISTRATION' then Constants::NationCollectors::COLLECT_ADMINISTRATION
             when 'DEFENCE' then Constants::NationCollectors::COLLECT_DEFENCE
             when 'EDUCATION' then Constants::NationCollectors::COLLECT_EDUCATION
             when 'ENVIRONMENT' then Constants::NationCollectors::COLLECT_ENVIRONMENT
             when 'HEALTHCARE' then Constants::NationCollectors::COLLECT_HEALTHCARE
             when 'COMMERCE' then Constants::NationCollectors::COLLECT_COMMERCE
             when 'INTERNATIONALAID' then Constants::NationCollectors::COLLECT_INTERNATIONALAID
             when 'LAWANDORDER' then Constants::NationCollectors::COLLECT_LAWANDORDER
             when 'PUBLICTRANSPORT' then Constants::NationCollectors::COLLECT_PUBLICTRANSPORT
             when 'SOCIALEQUALITY' then Constants::NationCollectors::COLLECT_SOCIALEQUALITY
             when 'SPIRITUALITY' then Constants::NationCollectors::COLLECT_SPIRITUALITY
             when 'WELFARE' then Constants::NationCollectors::COLLECT_WELFARE
             when 'FOUNDED' then Constants::NationCollectors::COLLECT_FOUNDED
             when 'FIRSTLOGIN' then Constants::NationCollectors::COLLECT_FIRSTLOGIN
             when 'LASTLOGIN' then Constants::NationCollectors::COLLECT_LASTLOGIN
             when 'LASTACTIVITY' then Constants::NationCollectors::COLLECT_LASTACTIVITY
             when 'INFLUENCE' then Constants::NationCollectors::COLLECT_INFLUENCE
             when 'PUBLICSECTOR' then Constants::NationCollectors::COLLECT_PUBLICSECTOR
             when 'CAUSE'
               @current_death_cause[:cause] = attrs['type']
               @state = Constants::NationCollectors::COLLECT_CAUSE
             when 'LEADER' then Constants::NationCollectors::COLLECT_LEADER
             when 'CAPITAL' then Constants::NationCollectors::COLLECT_CAPITAL
             when 'RELIGION' then Constants::NationCollectors::COLLECT_RELIGION
             when 'FACTBOOKS' then Constants::NationCollectors::COLLECT_FACTBOOKS
             when 'DISPATCHES' then Constants::NationCollectors::COLLECT_DISPATCHES
             when 'DBID' then Constants::NationCollectors::COLLECT_DBID
             else Constants::NationCollectors::COLLECT_NOTHING
             end
  end

  #
  # Collect value from current element and set to @current_*
  #
  # @param [String] string Element value
  #
  def characters(string)
    case @state
    when Constants::NationCollectors::COLLECT_NAME then @current_name = string
    when Constants::NationCollectors::COLLECT_TYPE then @current_type = string
    when Constants::NationCollectors::COLLECT_FULLNAME then @current_fullname = string
    when Constants::NationCollectors::COLLECT_MOTTO then @current_motto = string
    when Constants::NationCollectors::COLLECT_CATEGORY then @current_category = string
    when Constants::NationCollectors::COLLECT_UNSTATUS then @current_unstatus = string
    when Constants::NationCollectors::COLLECT_ENDORSEMENTS
      string.split(',').each do |endorsement|
        @current_endorsements << endorsement.strip
      end
    when Constants::NationCollectors::COLLECT_ISSUES_ANSWERED then @current_issues_answered = string.to_i
    when Constants::NationCollectors::COLLECT_CIVILRIGHTS
      if string.integer?
        @current_freedomscores_civilrights = string.to_f
      else
        @current_freedom_civilrights = string
      end
    when Constants::NationCollectors::COLLECT_ECONOMY
      if string.integer?
        @current_freedomscores_economy = string.to_f
      else
        @current_freedom_economy = string
      end
    when Constants::NationCollectors::COLLECT_POLITICALFREEDOM
      if string.integer?
        @current_freedomscores_politicalfreedom = string.to_f
      else
        @current_freedom_politicalfreedom = string
      end
    when Constants::NationCollectors::COLLECT_REGION then @current_region = string
    when Constants::NationCollectors::COLLECT_POPULATION then @current_population = string.to_i
    when Constants::NationCollectors::COLLECT_TAX then @current_tax = string.to_f
    when Constants::NationCollectors::COLLECT_ANIMAL then @current_animal = string
    when Constants::NationCollectors::COLLECT_CURRENCY then @current_currency = string
    when Constants::NationCollectors::COLLECT_DEMONYM then @current_demonym = string
    when Constants::NationCollectors::COLLECT_DEMONYM2 then @current_demonym2 = string
    when Constants::NationCollectors::COLLECT_DEMONYM2PLURAL then @current_demonym2plural = string
    when Constants::NationCollectors::COLLECT_FLAG then @current_flag = string
    when Constants::NationCollectors::COLLECT_MAJORINDUSTRY then @current_majorindustry = string
    when Constants::NationCollectors::COLLECT_GOVTPRIORITY then @current_govtpriority = string
    when Constants::NationCollectors::COLLECT_ADMINISTRATION then @current_administration = string.to_f
    when Constants::NationCollectors::COLLECT_DEFENCE then @current_defence = string.to_f
    when Constants::NationCollectors::COLLECT_EDUCATION then @current_education = string.to_f
    when Constants::NationCollectors::COLLECT_ENVIRONMENT then @current_environment = string.to_f
    when Constants::NationCollectors::COLLECT_HEALTHCARE then @current_healthcare = string.to_f
    when Constants::NationCollectors::COLLECT_COMMERCE then @current_commerce = string.to_f
    when Constants::NationCollectors::COLLECT_INTERNATIONALAID then @current_internationalaid = string.to_f
    when Constants::NationCollectors::COLLECT_LAWANDORDER then @current_lawandorder = string.to_f
    when Constants::NationCollectors::COLLECT_SPIRITUALITY then @current_spirituality = string.to_f
    when Constants::NationCollectors::COLLECT_WELFARE then @current_welfare = string.to_f
    when Constants::NationCollectors::COLLECT_FOUNDED then @current_founded = string
    when Constants::NationCollectors::COLLECT_FIRSTLOGIN then @current_firstlogin = string.to_i
    when Constants::NationCollectors::COLLECT_LASTLOGIN then @current_lastlogin = string.to_i
    when Constants::NationCollectors::COLLECT_LASTACTIVITY then @current_lastactivity = string
    when Constants::NationCollectors::COLLECT_INFLUENCE then @current_influence = string
    when Constants::NationCollectors::COLLECT_PUBLICSECTOR then @current_publicsector = string.to_f
    when Constants::NationCollectors::COLLECT_CAUSE then @current_death_cause[:value] = string.to_f
    when Constants::NationCollectors::COLLECT_LEADER then @current_leader = string
    when Constants::NationCollectors::COLLECT_CAPITAL then @current_capital = string
    when Constants::NationCollectors::COLLECT_RELIGION then @current_religion = string
    when Constants::NationCollectors::COLLECT_FACTBOOKS then @current_factbooks = string.to_i
    when Constants::NationCollectors::COLLECT_DISPATCHES then @current_dispatches = string.to_i
    when Constants::NationCollectors::COLLECT_DBID then @current_dbid = string.to_i
    end
  end

  #
  # Append current death cause to @death_causes array
  # Append current nation to @nations array and reset state
  # Set state to COLLECT_NOTHING
  #
  # @param [String] name Element name
  #
  def end_element(name)
    case name
    when 'CAUSE'
      @current_deaths << @current_death_cause
      @current_death_cause = { cause: '', value: 0 }
      @state = Constants::NationCollectors::COLLECT_NOTHING
    when 'NATION'
      @current_nation = {
        name: @current_name,
        type: @current_type,
        fullname: @current_fullname,
        motto: @current_motto,
        category: @current_category,
        unstatus: @current_unstatus,
        endorsements: @current_endorsements,
        issues_answered: @current_issues_answered,
        freedom: {
          civilrights: @current_freedom_civilrights,
          economy: @current_freedom_economy,
          politicalfreedom: @current_freedom_politicalfreedom
        },
        region: @current_region,
        population: @current_population,
        tax: @current_tax,
        animal: @current_animal,
        currency: @current_currency,
        demonym: @current_demonym,
        demonym2: @current_demonym2,
        demonym2plural: @current_demonym2plural,
        flag: @current_flag,
        majorindustry: @current_majorindustry,
        govtpriority: @current_govtpriority,
        govt: {
          administration: @current_administration,
          defence: @current_defence,
          education: @current_education,
          environment: @current_environment,
          healthcare: @current_healthcare,
          commerce: @current_commerce,
          internationalaid: @current_internationalaid,
          lawandorder: @current_lawandorder,
          publictransport: @current_publictransport,
          socialequality: @current_socialequality,
          spirituality: @current_spirituality,
          welfare: @current_welfare
        },
        founded: @current_founded,
        firstlogin: @current_firstlogin,
        lastlogin: @current_lastlogin,
        lastactivity: @current_lastactivity,
        influence: @current_influence,
        freedomscores: {
          civilrights: @current_freedomscores_civilrights,
          economy: @current_freedomscores_economy,
          politicalfreedom: @current_freedomscores_politicalfreedom
        },
        publicsector: @current_publicsector,
        deaths: @current_deaths,
        leader: @current_leader,
        capital: @current_capital,
        religion: @current_religion,
        factbooks: @current_factbooks,
        dispatches: @current_dispatches,
        dbid: @current_dbid
      }

      @nations << @current_nation
      reset_state
    else
      @state = Constants::NationCollectors::COLLECT_NOTHING
    end
  end

  #
  # Import @nations, an array of hashes, to database
  # Update duplicate nations with new data
  #
  def end_document
    Nation.import @nations,
                  on_duplicate_key_update: %i[
                    type
                    fullname
                    motto
                    category
                    unstatus
                    endorsements
                    issues_answered
                    freedom
                    region
                    population
                    tax
                    animal
                    currency
                    demonym
                    demonym2
                    demonym2plural
                    flag
                    majorindustry
                    govtpriority
                    govt
                    founded
                    firstlogin
                    lastlogin
                    lastactivity
                    influence
                    freedomscores
                    publicsector
                    deaths
                    leader
                    capital
                    religion
                    factbooks
                    dispatches
                    dbid
                  ],
                  validate: false,
                  batch_size: 1000
  end
end

#
# SAX parser for regions.xml
# Creates an array of hashes of nation data and passes to activerecord-import
#
class RegionParser < Nokogiri::XML::SAX::Document
  #
  # Initialize regions array and reset state
  #
  def initialize
    @regions = []
    reset_state
  end

  #
  # Reset state when starting a new region
  #
  #
  def reset_state
    @current_region = {}
    @state = Constants::RegionCollectors::COLLECT_NOTHING
    @current_officers = []
    @current_embassies = []
    @current_name = ''
    @current_factbook = ''
    @current_numnations = 0
    @current_nations = []
    @current_delegate = ''
    @current_delegatevotes = 0
    @current_delegateauth = ''
    @current_founder = ''
    @current_founderauth = ''
    @current_officer_nation = ''
    @current_officer_office = ''
    @current_officer_authority = ''
    @current_officer_time = 0
    @current_officer_by = ''
    @current_officer_order = 0
    @current_power = ''
    @current_flag = ''
    @current_banner = 0
    @current_embassy = {
      type: '',
      name: ''
    }
    @current_lastupdate = 0
  end

  #
  # Collect data from current element and set the state
  #
  # @param [String] name Element name
  # @param [Array] attrs Element attributes
  #
  # @return [String] Collector state
  #
  def start_element(name, attrs = [])
    @state = case name
             when 'NAME' then Constants::RegionCollectors::COLLECT_NAME
             when 'FACTBOOK' then Constants::RegionCollectors::COLLECT_FACTBOOK
             when 'NUMNATIONS' then Constants::RegionCollectors::COLLECT_NUMNATIONS
             when 'NATIONS' then Constants::RegionCollectors::COLLECT_NATIONS
             when 'DELEGATE' then Constants::RegionCollectors::COLLECT_DELEGATE
             when 'DELEGATEVOTES' then Constants::RegionCollectors::COLLECT_DELEGATEVOTES
             when 'DELEGATEAUTH' then Constants::RegionCollectors::COLLECT_DELEGATEAUTH
             when 'FOUNDER' then Constants::RegionCollectors::COLLECT_FOUNDER
             when 'FOUNDERAUTH' then Constants::RegionCollectors::COLLECT_FOUNDERAUTH
             when 'NATION' then Constants::RegionCollectors::COLLECT_OFFICER_NATION
             when 'OFFICE' then Constants::RegionCollectors::COLLECT_OFFICER_OFFICE
             when 'AUTHORITY' then Constants::RegionCollectors::COLLECT_OFFICER_AUTHORITY
             when 'TIME' then Constants::RegionCollectors::COLLECT_OFFICER_TIME
             when 'BY' then Constants::RegionCollectors::COLLECT_OFFICER_BY
             when 'ORDER' then Constants::RegionCollectors::COLLECT_OFFICER_ORDER
             when 'POWER' then Constants::RegionCollectors::COLLECT_POWER
             when 'FLAG' then Constants::RegionCollectors::COLLECT_FLAG
             when 'BANNER' then Constants::RegionCollectors::COLLECT_BANNER
             when 'EMBASSY'
               @current_embassy[:type] = if attrs.empty?
                                           ''
                                         else
                                           (attrs[0] == 'type' ? '' : attrs[0][1])
                                         end
               @state = Constants::RegionCollectors::COLLECT_EMBASSY
             when 'LASTUPDATE' then Constants::RegionCollectors::COLLECT_LASTUPDATE
             else Constants::RegionCollectors::COLLECT_NOTHING
             end
  end

  #
  # Collect value from current element and set to @current_*
  #
  # @param [String] string Element value
  #
  def characters(string)
    case @state
    when Constants::RegionCollectors::COLLECT_NAME then @current_name = string
    when Constants::RegionCollectors::COLLECT_FACTBOOK then @current_factbook = string
    when Constants::RegionCollectors::COLLECT_NUMNATIONS then @current_numnations = string.to_i
    when Constants::RegionCollectors::COLLECT_NATIONS
      string.split(':').each do |nation|
        @current_nations << nation.strip
      end
    when Constants::RegionCollectors::COLLECT_DELEGATE then @current_delegate = string
    when Constants::RegionCollectors::COLLECT_DELEGATEVOTES then @current_delegatevotes = string.to_i
    when Constants::RegionCollectors::COLLECT_DELEGATEAUTH then @current_delegateauth = string
    when Constants::RegionCollectors::COLLECT_FOUNDER then @current_founder = string
    when Constants::RegionCollectors::COLLECT_FOUNDERAUTH then @current_founderauth = string
    when Constants::RegionCollectors::COLLECT_OFFICER_NATION then @current_officer_nation = string
    when Constants::RegionCollectors::COLLECT_OFFICER_OFFICE then @current_officer_office = string
    when Constants::RegionCollectors::COLLECT_OFFICER_AUTHORITY then @current_officer_authority = string
    when Constants::RegionCollectors::COLLECT_OFFICER_TIME then @current_officer_time = string.to_i
    when Constants::RegionCollectors::COLLECT_OFFICER_BY then @current_officer_by = string
    when Constants::RegionCollectors::COLLECT_OFFICER_ORDER then @current_officer_order = string.to_i
    when Constants::RegionCollectors::COLLECT_POWER then @current_power = string
    when Constants::RegionCollectors::COLLECT_FLAG then @current_flag = string
    when Constants::RegionCollectors::COLLECT_BANNER then @current_banner = string.to_i
    when Constants::RegionCollectors::COLLECT_EMBASSY then @current_embassy[:name] = string
    when Constants::RegionCollectors::COLLECT_LASTUPDATE then @current_lastupdate = string.to_i
    end
  end

  #
  # Append current embassy to @current_embassies
  # Append current region to @regions array and reset state
  # Set state to COLLECT_NOTHING
  #
  # @param [String] name Element name
  #
  def end_element(name)
    case name
    when 'EMBASSY'
      @current_embassies << @current_embassy
      @current_embassy = { type: '', name: '' }
      @state = Constants::RegionCollectors::COLLECT_NOTHING
    when 'REGION'
      @current_region = {
        name: @current_name,
        factbook: @current_factbook,
        numnations: @current_numnations,
        nations: @current_nations,
        delegate: @current_delegate,
        delegatevotes: @current_delegatevotes,
        delegateauth: @current_delegateauth,
        founder: @current_founder,
        founderauth: @current_founderauth,
        officers: @current_officers,
        embassies: @current_embassies,
        lastupdate: @current_lastupdate
      }
      @regions << @current_region
      reset_state
    else
      @state = Constants::RegionCollectors::COLLECT_NOTHING
    end
  end

  #
  # Import @regions, an array of hashes, to database
  # Update duplicate regions with new data
  #
  def end_document
    Region.import @regions,
                  on_duplicate_key_update: %i[
                    factbook
                    numnations
                    nations
                    delegate
                    delegatevotes
                    delegateauth
                    founder
                    founderauth
                    officers
                    embassies
                    lastupdate
                  ],
                  validate: false,
                  batch_size: 1000
  end
end

desc 'Parse XML file and import to database'

namespace :parse do
  task regions: :environment do
    parser = Nokogiri::XML::SAX::Parser.new(RegionParser.new)
    parser.parse(File.open('storage/dumps/regions.xml'))
    Rails.logger.info "Parsed regions at #{Time.zone.now}"
  end

  task nations: :environment do
    parser = Nokogiri::XML::SAX::Parser.new(NationParser.new)
    parser.parse(File.open('storage/dumps/nations.xml'))
    Rails.logger.info "Parsed nations at #{Time.zone.now}"
  end
end
