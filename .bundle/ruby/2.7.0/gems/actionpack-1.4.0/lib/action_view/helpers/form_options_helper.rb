require 'cgi'
require 'erb'
require File.dirname(__FILE__) + '/form_helper'

module ActionView
  module Helpers
    # Provides a number of methods for turning different kinds of containers into a set of option tags.
    module FormOptionsHelper
      include ERB::Util

      # Create a select tag and a series of contained option tags for the provided object and method.
      # The option currenlty held by the object will be selected, provided that the object is available.
      # 
      # This can be used to provide a default set of options in the standard way: before rendering the create form, a
      # new model instance is assigned the default options and bound to @model_name. Usually this model is not saved
      # to the database. Instead, a second model object is created when the create request is received.
      # This allows the user to submit a form page more than once with the expected results of creating multiple records.
      # In addition, this allows a single partial to be used to generate form inputs for both edit and create forms.
      def select(object, method, choices, options = {}, html_options = {})
        InstanceTag.new(object, method, self).to_select_tag(choices, options, html_options)
      end
        
      # Return select and option tags for the given object and method using options_from_collection_for_select to generate the list of option tags.
      def collection_select(object, method, collection, value_method, text_method, options = {}, html_options = {})
        InstanceTag.new(object, method, self).to_collection_select_tag(collection, value_method, text_method, options, html_options)
      end
      
      # Return select and option tags for the given object and method, using country_options_for_select to generate the list of option tags.
      def country_select(object, method, priority_countries = nil, options = {}, html_options = {})
        InstanceTag.new(object, method, self).to_country_select_tag(priority_countries, options, html_options)
      end
      
      # Accepts a container (hash, array, enumerable, your type) and returns a string of option tags. Given a container 
      # where the elements respond to first and last (such as a two-element array), the "lasts" serve as option values and
      # the "firsts" as option text. Hashes are turned into this form automatically, so the keys become "firsts" and values
      # become lasts. If +selected+ is specified, the matching "last" or element will get the selected option-tag.  +Selected+
      # may also be an array of values to be selected when using a multiple select.
      #
      # Examples (call, result):
      #   options_for_select([["Dollar", "$"], ["Kroner", "DKK"]])
      #     <option value="$">Dollar</option>\n<option value="DKK">Kroner</option>
      #
      #   options_for_select([ "VISA", "Mastercard" ], "Mastercard")
      #     <option>VISA</option>\n<option selected="selected">Mastercard</option>
      #
      #   options_for_select({ "Basic" => "$20", "Plus" => "$40" }, "$40")
      #     <option value="$20">Basic</option>\n<option value="$40" selected="selected">Plus</option>
      #
      #   options_for_select([ "VISA", "Mastercard", "Discover" ], ["VISA", "Discover"])
      #     <option selected="selected">VISA</option>\n<option>Mastercard</option>\n<option selected="selected">Discover</option>
      def options_for_select(container, selected = nil)
        container = container.to_a if Hash === container
      
        options_for_select = container.inject([]) do |options, element| 
          if element.respond_to?(:first) && element.respond_to?(:last)
            is_selected = ( (selected.respond_to?(:include?) ? selected.include?(element.last) : element.last == selected) )
            if is_selected
              options << "<option value=\"#{html_escape(element.last.to_s)}\" selected=\"selected\">#{html_escape(element.first.to_s)}</option>"
            else
              options << "<option value=\"#{html_escape(element.last.to_s)}\">#{html_escape(element.first.to_s)}</option>"
            end
          else
            is_selected = ( (selected.respond_to?(:include?) ? selected.include?(element) : element == selected) )
            options << ((is_selected) ? "<option selected=\"selected\">#{html_escape(element.to_s)}</option>" : "<option>#{html_escape(element.to_s)}</option>")
          end
        end
        
        options_for_select.join("\n")
      end

      # Returns a string of option tags that has been compiled by iterating over the +collection+ and assigning the 
      # the result of a call to the +value_method+ as the option value and the +text_method+ as the option text.
      # If +selected_value+ is specified, the element returning a match on +value_method+ will get the selected option tag.
      #
      # Example (call, result). Imagine a loop iterating over each +person+ in <tt>@project.people</tt> to generate a input tag:
      #   options_from_collection_for_select(@project.people, "id", "name")
      #     <option value="#{person.id}">#{person.name}</option>
      def options_from_collection_for_select(collection, value_method, text_method, selected_value = nil)
        options_for_select(
          collection.inject([]) { |options, object| options << [ object.send(text_method), object.send(value_method) ] }, 
          selected_value
        )
      end

      # Returns a string of option tags, like options_from_collection_for_select, but surrounds them by <optgroup> tags.
      #
      # An array of group objects are passed. Each group should return an array of options when calling group_method
      # Each group should should return its name when calling group_label_method.
      #
      # html_option_groups_from_collection(@continents, "countries", "contient_name", "country_id", "country_name", @selected_country.id)
      #
      # Could become:
      #  <optgroup label="Africa">
      #   <select>Egypt</select>
      #   <select>Rwanda</select>
      #   ...
      #  </optgroup>
      #  <optgroup label="Asia">
      #   <select>China</select>
      #   <select>India</select>
      #   <select>Japan</select>
      #   ...
      #  </optgroup>
      #
      # with objects of the following classes:
      # class Continent
      #	  def initialize(p_name, p_countries)	@continent_name = p_name; @countries = p_countries;	end
      #	  def continent_name() @continent_name; end
      #	  def countries() @countries; end
      # end
      # class Country
      #	  def initialize(id, name) @id = id; @name = name end
      #	  def country_id() @id; end
      #	  def country_name() @name; end
      # end
      def option_groups_from_collection_for_select(collection, group_method, group_label_method, 
            option_key_method, option_value_method, selected_key = nil)
        collection.inject("") do |options_for_select, group|
          group_label_string = eval("group.#{group_label_method}")
          options_for_select += "<optgroup label=\"#{html_escape(group_label_string)}\">"
          options_for_select += options_from_collection_for_select(eval("group.#{group_method}"), option_key_method, option_value_method, selected_key)
          options_for_select += '</optgroup>'
        end
      end	
      
      # Returns a string of option tags for pretty much any country in the world. Supply a country name as +selected+ to 
      # have it marked as the selected option tag. You can also supply an array of countries as +priority_countries+, so
      # that they will be listed above the rest of the (long) list.
      def country_options_for_select(selected = nil, priority_countries = nil)
        country_options = ""
        
        if priority_countries
          country_options += options_for_select(priority_countries, selected)
          country_options += "<option>-------------</option>\n"
        end

        if priority_countries && priority_countries.include?(selected)
          country_options += options_for_select(COUNTRIES - priority_countries, selected)
        else
          country_options += options_for_select(COUNTRIES, selected)
        end

        return country_options
      end


      private
        # All the countries included in the country_options output.
        COUNTRIES = [ "Albania", "Algeria", "American Samoa", "Andorra", "Angola", "Anguilla", 
            "Antarctica", "Antigua And Barbuda", "Argentina", "Armenia", "Aruba", "Australia", 
            "Austria", "Azerbaijan", "Bahamas", "Bahrain", "Bangladesh", "Barbados", "Belarus", 
            "Belgium", "Belize", "Benin", "Bermuda", "Bhutan", "Bolivia", "Bosnia and Herzegowina", 
            "Botswana", "Bouvet Island", "Brazil", "British Indian Ocean Territory", 
            "Brunei Darussalam", "Bulgaria", "Burkina Faso", "Burma", "Burundi", "Cambodia", 
            "Cameroon", "Canada", "Cape Verde", "Cayman Islands", "Central African Republic", 
            "Chad", "Chile", "China", "Christmas Island", "Cocos (Keeling) Islands", "Colombia", 
            "Comoros", "Congo", "Congo, the Democratic Republic of the", "Cook Islands", 
            "Costa Rica", "Cote d'Ivoire", "Croatia", "Cyprus", "Czech Republic", "Denmark", 
            "Djibouti", "Dominica", "Dominican Republic", "East Timor", "Ecuador", "Egypt", 
            "El Salvador", "England", "Equatorial Guinea", "Eritrea", "Espana", "Estonia", 
            "Ethiopia", "Falkland Islands", "Faroe Islands", "Fiji", "Finland", "France", 
            "French Guiana", "French Polynesia", "French Southern Territories", "Gabon", "Gambia", 
            "Georgia", "Germany", "Ghana", "Gibraltar", "Great Britain", "Greece", "Greenland", 
            "Grenada", "Guadeloupe", "Guam", "Guatemala", "Guinea", "Guinea-Bissau", "Guyana", 
            "Haiti", "Heard and Mc Donald Islands", "Honduras", "Hong Kong", "Hungary", "Iceland", 
            "India", "Indonesia", "Ireland", "Israel", "Italy", "Jamaica", "Japan", "Jordan", 
            "Kazakhstan", "Kenya", "Kiribati", "Korea, Republic of", "Korea (South)", "Kuwait", 
            "Kyrgyzstan", "Lao People's Democratic Republic", "Latvia", "Lebanon", "Lesotho", 
            "Liberia", "Liechtenstein", "Lithuania", "Luxembourg", "Macau", "Macedonia", 
            "Madagascar", "Malawi", "Malaysia", "Maldives", "Mali", "Malta", "Marshall Islands", 
            "Martinique", "Mauritania", "Mauritius", "Mayotte", "Mexico", 
            "Micronesia, Federated States of", "Moldova, Republic of", "Monaco", "Mongolia", 
            "Montserrat", "Morocco", "Mozambique", "Myanmar", "Namibia", "Nauru", "Nepal", 
            "Netherlands", "Netherlands Antilles", "New Caledonia", "New Zealand", "Nicaragua", 
            "Niger", "Nigeria", "Niue", "Norfolk Island", "Northern Ireland", 
            "Northern Mariana Islands", "Norway", "Oman", "Pakistan", "Palau", "Panama", 
            "Papua New Guinea", "Paraguay", "Peru", "Philippines", "Pitcairn", "Poland", 
            "Portugal", "Puerto Rico", "Qatar", "Reunion", "Romania", "Russia", "Rwanda", 
            "Saint Kitts and Nevis", "Saint Lucia", "Saint Vincent and the Grenadines", 
            "Samoa (Independent)", "San Marino", "Sao Tome and Principe", "Saudi Arabia", 
            "Scotland", "Senegal", "Seychelles", "Sierra Leone", "Singapore", "Slovakia", 
            "Slovenia", "Solomon Islands", "Somalia", "South Africa", 
            "South Georgia and the South Sandwich Islands", "South Korea", "Spain", "Sri Lanka", 
            "St. Helena", "St. Pierre and Miquelon", "Suriname", "Svalbard and Jan Mayen Islands", 
            "Swaziland", "Sweden", "Switzerland", "Taiwan", "Tajikistan", "Tanzania", "Thailand", 
            "Togo", "Tokelau", "Tonga", "Trinidad", "Trinidad and Tobago", "Tunisia", "Turkey", 
            "Turkmenistan", "Turks and Caicos Islands", "Tuvalu", "Uganda", "Ukraine", 
            "United Arab Emirates", "United Kingdom", "United States", 
            "United States Minor Outlying Islands", "Uruguay", "Uzbekistan", "Vanuatu", 
            "Vatican City State (Holy See)", "Venezuela", "Viet Nam", "Virgin Islands (British)", 
            "Virgin Islands (U.S.)", "Wales", "Wallis and Futuna Islands", "Western Sahara", 
            "Yemen", "Zambia", "Zimbabwe" ] unless const_defined?("COUNTRIES")
    end

    class InstanceTag #:nodoc:
      include FormOptionsHelper

      def to_select_tag(choices, options, html_options)
        add_default_name_and_id(html_options)
        content_tag("select", add_blank_option(options_for_select(choices, value), options[:include_blank]), html_options)
      end

      def to_collection_select_tag(collection, value_method, text_method, options, html_options)
        add_default_name_and_id(html_options)
        content_tag(
          "select", add_blank_option(options_from_collection_for_select(collection, value_method, text_method, value), options[:include_blank]), html_options
        )
      end
      
      def to_country_select_tag(priority_countries, options, html_options)
        add_default_name_and_id(html_options)
        content_tag("select", add_blank_option(country_options_for_select(value, priority_countries), options[:include_blank]), html_options)
      end

      private
        def add_blank_option(option_tags, add_blank)
          add_blank ? "<option></option>\n" + option_tags : option_tags
        end
    end
  end
end
