#!/usr/bin/env ruby

require_relative './app_lib_test_base'

class LanguagesDisplayNamesSplitter

  def initialize(display_names,selected_index)
    @display_names,@selected_index = display_names,selected_index
  end
  
  def languages_names
    @languages_names ||= split(0)
  end
  
  def language_selected_index
    language_name = @display_names[@selected_index].split(',')[0].strip
    languages_names.index(language_name)
  end
  
  def tests_names
    @tests_names ||= split(1)
  end
  
  def tests_indexes
    languages_names.map { |name| make_test_indexes(name) }
  end
  
private

  def split(n)
    @display_names.map{|name| name.split(',')[n].strip }.sort.uniq
  end

  def make_test_indexes(language_name)
    result = [ ]
    @display_names.each { |name|
      if name.start_with?(language_name + ',')
        test_name = name.split(',')[1].strip
        result << tests_names.index(test_name)
      end
    }
    result.shuffle
    
    # if this is the tests index array for the selected-language
    # then make sure the index for the selected-language's test 
    # is at position zero.
    
    if language_name === languages_names[language_selected_index]
      test_name = @display_names[@selected_index].split(',')[1].strip
      test_index = tests_names.index(test_name)
      result.delete(test_index)
      result.unshift(test_index)
    end

    result
  end  
  
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - -

class LanguageSplitterTests < AppLibTestBase

  test 'display_names is split on comma into [languages_names,tests_names]' do
    
    # At present 
    # o) the languages' display_names combine the name of the 
    #    language *and* the name of the test framework.
    # o) The languages/ folder does *not* have a nested structure. 
    #    It probably should have.
    #
    # It makes sense to mirror the pattern of each language having its
    # own docker image, and sub folders underneath it add their
    # own test framework, and implicitly use their parents folder's
    # docker image to build FROM in their Dockerfile
  
    languages_display_names = [
      'C++, GoogleTest',  
      'C++, assert',      # <----- selected
      'C, assert',        
      'C, Unity',
      'C, Igloo',
      'Go, testing'
    ]
    
    selected_index = languages_display_names.index('C++, assert')
    assert_equal 1, selected_index
    
    split = LanguagesDisplayNamesSplitter.new(languages_display_names, selected_index)
    
    assert_equal [
      'C',   
      'C++',  # <----- selected_index
      'Go'
    ], split.languages_names
    
    assert_equal [
      'GoogleTest',  # 0
      'Igloo',       # 1
      'Unity',       # 2
      'assert',      # 3
      'testing'      # 4
    ], split.tests_names

    # Need to know which tests names to display and initially select
    # Make the indexes *not* sorted and the
    # first entry in each array is the initial selection
    
    indexes =   
    [
      [ # C
        1,  # Igloo   (C, Igloo)
        2,  # Unity   (C, Unity)
        3,  # assert  (C, assert)    
      ],
      [ # C++
        0,  # GoogleTest  (C++, GoogleTest)     
        3,  # assert      (C++, assert)         <---- selected
      ],
      [ # Go
        4,  # testing     (Go, testing)         
      ]
    ]
      
    actual = split.tests_indexes
    assert_equal indexes.length, actual.length
    
    indexes.each_with_index {|array,at|
      assert_equal array, actual[at].sort
    }
    
    assert_equal 1, split.language_selected_index   # C++
    assert_equal 3, split.tests_indexes[1][0]       # assert
    
  end

end
