class PokeUtil

  def initialize(options = {})
  end

  def self.player_error player='', players=[]
    printf "\tPlayer '#{player}'' not found in your config file. Valid players are:  [#{players.join(' ')}]\n".light_yellow
  end

  def self.place_error place='', places=[]
    printf "\tPlace '#{place}' not found in your config file.  Valid places are: [#{places.join(' ')}] \n".light_yellow
  end

  def self.location_error location
    printf "\tUnknow location type. Please use only 'coord' or 'location' in places on your config file. Aborting...\n".light_yellow
    ap location
    exit
  end

  def self.encrypt_library_error
    printf "\tUnknow library key on your config file. Aborting...\n".light_yellow
    exit
  end

  def self.verify_library library
    ap library
    host_os = RbConfig::CONFIG['host_os']
    ap host_os
  end

  def self.read_config 

    #local = ENV['PWD']
    file = open(PokeMan.configuration.pwd+'/pokeman.config')
    json = file.read
    parsed = JSON.parse(json)
    config  = parsed
    players = config.keys
    players.delete('places')
    players.delete('library')
    PokeUtil.set_variable 'config', config
    PokeUtil.set_variable 'players', players
    PokeUtil.set_variable 'place', config['places']['default']
    places = config['places'].keys
    places.delete('default')
    set_variable 'places', places 
    levels = YAML.load(File.read(PokeMan.files + '/levels.yml'))
    evolutions = YAML.load(File.read(PokeMan.files + '/evolutions.yml'))
    PokeUtil.set_variable 'levels', levels
    PokeUtil.set_variable 'evolutions', evolutions
  end

  def self.login login, place
    config = get_variable 'config'

    # Instantiate our client
    client = Poke::API::Client.new

    location = config['places'][place]

    case location['type']
    when 'coord'
      lat  = location['lat']
      long = location['long']
      client.store_lat_lng(lat, long)
    when 'location'
      lat  = location['location']
      client.store_location('Rio de Janeiro')
    else
      location_error location
    end
    cell_ids = Poke::API::Helpers.get_cells(client.lat, client.lng)

    user            = config[login]['user']
    password        = config[login]['password']
    account_type    = config[login]['account_type']

    unless config['library'].nil?
      encrypt_library = config['library']
      verify_library encrypt_library
    else
      encrypt_library_error
    end

    # Activate the encryption method to generate a signature (only required for map objects)
    client.activate_signature(encrypt_library)
    client.login(user, password, account_type)

    # Construct map objects call
    client.get_map_objects(
      latitude: client.lat,
      longitude: client.lng,
      since_timestamp_ms: [0] * cell_ids.length,
      cell_id: cell_ids
    )

    # Add more calls
    client.get_player
    client.get_inventory

    # Call and view response
    response = client.call
    set_variable 'pokeclient', client
    get_data response
  end

  def self.get_items response

  end

  def self.get_data response
    general   = response.response[:GET_PLAYER]
    objects   = response.response[:GET_MAP_OBJECTS]
    inventory = response.response[:GET_INVENTORY]

    player   = {}
    pokemons = {}
    items    = {}
    pokedex  = {}
    candys   = {}

    player = {
      :name                 => general[:player_data][:username],
      :team                 => general[:player_data][:team],
      :max_pokemon_storage  => general[:player_data][:max_pokemon_storage],
      :max_item_storage     => general[:player_data][:max_item_storage],
      :currencies           => general[:player_data][:currencies],
    }

    inventory[:inventory_delta][:inventory_items].each do |item|

      unless item[:inventory_item_data].nil?

        unless item[:inventory_item_data][:pokemon_data].nil?

          p        = item[:inventory_item_data][:pokemon_data]
          level    = get_level  p[:cp_multiplier], p[:num_upgrades] 
          stardust = get_stardust level
          pokemons[p[:id]] = {
            :name               => p[:pokemon_id],
            :cp                 => p[:cp],
            :stamina            => p[:stamina],
            :stamina_max        => p[:stamina_max],
            :move_1             => p[:move_1],
            :move_2             => p[:move_2],
            :individual_attack  => p[:individual_attack],
            :individual_defense => p[:individual_defense],
            :individual_stamina => p[:individual_stamina],
            :cp_multiplier      => p[:cp_multiplier],
            :additional_cp_multiplier => p[:additional_cp_multiplier],
            :captured_cell_id   => p[:captured_cell_id],
            :battles_attacked   => p[:battles_attacked],
            :battles_defended   => p[:battles_defended],
            :creation_time_ms   => p[:creation_time_ms],
            :num_upgrades       => p[:num_upgrades],
            :special_attack     => 0,
            :special_defense    => 0,
            :speed              => 0,
            :level              => level,
            :stardust           => stardust,
          }

        unless p[:pokemon_id].eql? :MISSINGNO

          base_stamina = 2 * p[:stamina]
          a1 = Math.sqrt(p[:individual_attack]) 
          a2 = Math.sqrt(pokemons[p[:id]][:special_attack]) 
          a3 = Math.sqrt(pokemons[p[:id]][:speed])
          base_attack  = 2 * (a1 * a2 + a3).round

          d1 = Math.sqrt(p[:individual_defense])
          d2 = Math.sqrt(pokemons[p[:id]][:special_defense])
          d3 = Math.sqrt(pokemons[p[:id]][:speed])
          base_defense = 2 * (d1 * d2 + d3).round

          totalcp_multiplier = p[:cp_multiplier] + p[:additional_cp_multiplier]

          total_stamina = (base_stamina + p[:individual_stamina]) * totalcp_multiplier
          total_attack  = (base_attack  + p[:individual_attack])  * totalcp_multiplier
          total_defense = (base_defense + p[:individual_defense]) * totalcp_multiplier

          cp1 = Math.sqrt(total_stamina)
          cp2 = total_attack
          cp3 = Math.sqrt(total_defense)

          total_cp = (Math.sqrt(total_stamina) + total_attack + Math.sqrt(total_defense))/10

          pokemons[p[:id]][:total_cp]      = total_cp
          pokemons[p[:id]][:total_stamina] = total_stamina
          pokemons[p[:id]][:total_attack]  = total_attack
          pokemons[p[:id]][:total_defense] = total_defense
          pokemons[p[:id]][:rank] = (cp1 * cp2 * cp3)

        end

        end
        unless item[:inventory_item_data][:item].nil?
          i = item[:inventory_item_data][:item]
          items[i[:item_id]] = {
            :count  => i[:count],
            :unseen => i[:unseen],
          }
        end
        unless item[:inventory_item_data][:pokedex_entry].nil?
           player[:pokedex_entry] = item[:inventory_item_data][:pokedex_entry]
        end
        unless item[:inventory_item_data][:player_stats].nil?
          pdata = item[:inventory_item_data][:player_stats]
          player[:level]                  = pdata[:level]
          player[:experience]             = pdata[:experience]
          player[:prev_level_xp]          = pdata[:prev_level_xp]
          player[:next_level_xp]          = pdata[:next_level_xp]
          player[:km_walked]              = pdata[:km_walked]
          player[:pokemons_encountered]   = pdata[:pokemons_encountered]
          player[:unique_pokedex_entries] = pdata[:unique_pokedex_entries]
          player[:pokemons_captured]      = pdata[:pokemons_captured]
          player[:evolutions]             = pdata[:evolutions]
          player[:poke_stop_visits]       = pdata[:poke_stop_visits]
        end
        unless item[:inventory_item_data][:player_currency].nil?
          player[:player_currency] = item[:inventory_item_data][:player_currency]
        end
        unless item[:inventory_item_data][:player_camera].nil?
          player[:camera] = item[:inventory_item_data][:player_camera]
        end
        unless item[:inventory_item_data][:inventory_upgrades].nil?
          player[:inventory_upgrades] = item[:inventory_item_data][:inventory_upgrades]
        end
        unless item[:inventory_item_data][:applied_items].nil?
          player[:applied_items] = item[:inventory_item_data][:applied_items]
        end
        unless item[:inventory_item_data][:egg_incubators].nil?
          player[:egg_incubators] = item[:inventory_item_data][:egg_incubators]
        end
        unless item[:inventory_item_data][:candy].nil?
          candy = item[:inventory_item_data][:candy]
          candys[candy[:family_id]] =  candy[:candy]
        end

      end

    end

    set_variable 'player', player
    set_variable 'pokemons', pokemons
    set_variable 'items', items
    set_variable 'pokedex', pokedex
    set_variable 'candys', candys

  end


  def self.show_stats
    player   = PokeUtil.get_variable 'player'
    pokemons = PokeUtil.get_variable 'pokemons'
    paux = pokemons.sort_by{|k,v| v[:name]}
    puts
    paux.each do |k,p|
      unless p[:name].eql? :MISSINGNO
        printf "NAME        #{p[:name]}\n"
        printf "CP          #{p[:cp]}\n"
        printf "STAMINA     #{p[:stamina]}\n"
        printf "STAMINAMAX  #{p[:stamina_max]}\n"
        printf "PLEVEL      #{player[:level]}\n"
        printf "TotalUp     #{p[:num_upgrades]}\n"
        printf "ATTACK      #{p[:individual_attack]}\n"
        printf "DEFFENSE    #{p[:individual_defense]}\n"
        printf "ISTAMINA    #{p[:individual_stamina]}\n"
        printf "MOVE1       #{p[:move_1]}\n"
        printf "MOVE2       #{p[:move_2]}\n"
        totalcpx = p[:cp_multiplier] + p[:additional_cp_multiplier]
        printf "Totalx      #{totalcpx}\n"
        stardust = 0 #stardust_level pokelevel
        printf "STARDUST    #{stardust}\n\n"
        # data = "##{poke_id},#{p[:cp]},#{p[:stamina]},#{pokelevel},0"
        # printf "%-30s \t %s\n", p[:name].to_s.green , data.yellow
      end
    end
  end


  def self.show_stats2
    player   = PokeUtil.get_variable 'player'
    pokemons = PokeUtil.get_variable 'pokemons'
    paux = pokemons.sort_by{|k,v| v[:name]}
    puts
    printf " %15s", "Name"
    printf " %5s", "cp"
    printf " %5s", "sta"
    printf " %5s", "mst"
    printf " %5s", "upg"
    printf " %5s", "iatk"
    printf " %5s", "idef"
    printf " %5s", "ista"
    printf " %20s", "m1"
    printf " %20s", "m2"
    printf " %s",  "totcpx"
    puts
    paux.each do |k,p|
      unless p[:name].eql? :MISSINGNO
        totalcpx = p[:cp_multiplier] + p[:additional_cp_multiplier]

        printf " %15s", p[:name]
        printf " %5d",  p[:cp]
        printf " %5d",  p[:stamina]
        printf " %5d",  p[:stamina_max]
        printf " %5d",  p[:num_upgrades]
        printf " %5d",  p[:individual_attack]
        printf " %5d",  p[:individual_defense]
        printf " %5d",  p[:individual_stamina]
        printf " %20s", p[:move_1]
        printf " %20s", p[:move_2]
        printf " %f",   totalcpx
        puts
      end
    end
  end

  def self.show_stats3
    player   = PokeUtil.get_variable 'player'
    pokemons = PokeUtil.get_variable 'pokemons'
    paux = pokemons.sort_by{|k,v| v[:name]}
    data = []
    paux.each do |k,p|
      unless p[:name].eql? :MISSINGNO
        totalcpx = p[:cp_multiplier] + p[:additional_cp_multiplier]
        aux = []
        aux << p[:name]
        aux << p[:cp]
        aux << p[:stamina]
        aux << p[:stamina_max]
        aux << p[:num_upgrades]
        aux << p[:individual_attack]
        aux << p[:individual_defense]
        aux << p[:individual_stamina]
        aux << p[:move_1]
        aux << p[:move_2]
        aux << totalcpx
        data << aux
      end
    end
    puts
    table = TTY::Table.new ["Name","cp","sta","mst","upg","iatk","idef","ista","m1","m2","totcpx"], data
    puts table.render(:ascii)

  end

  def self.get_level  multiplier, upgrades
    levels = PokeUtil.get_variable 'levels'
    level  = levels.find_index(multiplier.round(8)) + upgrades * 0.5
    return level
  end

  def self.get_stardust  pokemon_level
    case pokemon_level
    when 0..2.999
      stardust = 200
    when 3..4.999
      stardust = 400
    when 5..6.999
      stardust = 600
    when 7..8.999
      stardust = 800
    when 9..10.999
      stardust = 1000
    when 11..12.999
      stardust = 1300
    when 13..14.999
      stardust = 1600
    when 15..16.999
      stardust = 1900
    when 17..18.999
      stardust = 2200
    when 19..20.999
      stardust = 2500
    when 21..22.999
      stardust = 3000
    when 23..24.999
      stardust = 3500
    when 25..26.999
      stardust = 4000
    when 27..28.999
      stardust = 4500
    when 29..30.999
      stardust = 5000
    when 31..32.999
      stardust = 6000
    when 33..34.999
      stardust = 7000
    when 35..36.999
      stardust = 8000
    when 37..38.999
      stardust = 9000
    when 39..1000
      stardust = 10000
    end
    return stardust
  end

  def self.get_poke_id pokemon
    poke_list = ['Bulbasaur',
    'Ivysaur',
    'Venusaur',
    'Charmander',
    'Charmeleon',
    'Charizard',
    'Squirtle',
    'Wartortle',
    'Blastoise',
    'Caterpie',
    'Metapod',
    'Butterfree',
    'Weedle',
    'Kakuna',
    'Beedrill',
    'Pidgey',
    'Pidgeotto',
    'Pidgeot',
    'Rattata',
    'Raticate',
    'Spearow',
    'Fearow',
    'Ekans',
    'Arbok',
    'Pikachu',
    'Raichu',
    'Sandshrew',
    'Sandslash',
    'Nidoran♀',
    'Nidorina',
    'Nidoqueen',
    'Nidoran♂',
    'Nidorino',
    'Nidoking',
    'Clefairy',
    'Clefable',
    'Vulpix',
    'Ninetales',
    'Jigglypuff',
    'Wigglytuff',
    'Zubat',
    'Golbat',
    'Oddish',
    'Gloom',
    'Vileplume',
    'Paras',
    'Parasect',
    'Venonat',
    'Venomoth',
    'Diglett',
    'Dugtrio',
    'Meowth',
    'Persian',
    'Psyduck',
    'Golduck',
    'Mankey',
    'Primeape',
    'Growlithe',
    'Arcanine',
    'Poliwag',
    'Poliwhirl',
    'Poliwrath',
    'Abra',
    'Kadabra',
    'Alakazam',
    'Machop',
    'Machoke',
    'Machamp',
    'Bellsprout',
    'Weepinbell',
    'Victreebel',
    'Tentacool',
    'Tentacruel',
    'Geodude',
    'Graveler',
    'Golem',
    'Ponyta',
    'Rapidash',
    'Slowpoke',
    'Slowbro',
    'Magnemite',
    'Magneton',
    'Farfetch',
    'Doduo',
    'Dodrio',
    'Seel',
    'Dewgong',
    'Grimer',
    'Muk',
    'Shellder',
    'Cloyster',
    'Gastly',
    'Haunter',
    'Gengar',
    'Onix',
    'Drowzee',
    'Hypno',
    'Krabby',
    'Kingler',
    'Voltorb',
    'Electrode',
    'Exeggcute',
    'Exeggutor',
    'Cubone',
    'Marowak',
    'Hitmonlee',
    'Hitmonchan',
    'Lickitung',
    'Koffing',
    'Weezing',
    'Rhyhorn',
    'Rhydon',
    'Chansey',
    'Tangela',
    'Kangaskhan',
    'Horsea',
    'Seadra',
    'Goldeen',
    'Seaking',
    'Staryu',
    'Starmie',
    'Mr. Mime',
    'Scyther',
    'Jynx',
    'Electabuzz',
    'Magmar',
    'Pinsir',
    'Tauros',
    'Magikarp',
    'Gyarados',
    'Lapras',
    'Ditto',
    'Eevee',
    'Vaporeon',
    'Jolteon',
    'Flareon',
    'Porygon',
    'Omanyte',
    'Omastar',
    'Kabuto',
    'Kabutops',
    'Aerodactyl',
    'Snorlax',
    'Articuno',
    'Zapdos',
    'Moltres',
    'Dratini',
    'Dragonair',
    'Dragonite',
    'Mewtwo',
    'Mew']
    pokeHash = {}
    index = 1
    poke_list.each do |pokename|
      pokeHash[pokename.downcase] = index
      index += 1
    end
    return pokeHash[pokemon.to_s.downcase]
  end

  def self.set_variable_ext variable, value
    if self.instance_variable_defined? ("@#{variable}")
      aux = self.get_variable variable
      case aux.class.to_s
      when 'String'
         self.set_variable variable, value
      when 'Hash'
         begin 
          aux.merge! value 
          self.set_variable variable, aux
        rescue
          CMDAPIUtil.show "\tCMDAPIUtil error [set_variable_ext]. Attempt insert #{variable.class} into Hash variable....".light_red
        end
      when 'Array'
        aux.insert(-1,value)
        self.set_variable variable, aux
      end
    end
  end

  def self.set_variable variable, value
    self.instance_variable_set("@#{variable}", value)
  end

  def self.get_variable variable
    return self.instance_variable_get("@#{variable}")
  end

  def self.show_variables
    self.instance_variables.sort.each do |v|
      variable = v.to_s.gsub('@','').to_s
      unless ['config','config_cmdapi'].include? variable
        printf "\t %30s \t %s\n", variable.yellow, (self.get_variable variable).to_s.green
      end
    end
  end

end