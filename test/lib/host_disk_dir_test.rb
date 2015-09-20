#!/bin/bash ../test_wrapper.sh

require_relative 'LibTestBase'

class HostDiskDirTests < LibTestBase

  def setup
    super
    `rm -rf #{path}`
    `mkdir -p #{path}`
  end

  def disk
    @disk ||= HostDisk.new
  end
  
  def path
    File.expand_path('../..', File.dirname(__FILE__)) + '/tmp/'
  end
  
  def dir
    disk[path]
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '437EB1',
  'disk[...].path always ends in /' do
    assert_equal "ABC/", disk['ABC'].path
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '0DB5F3',
  'disk[path].exists? false when path does not exist, true when it does' do
    `rm -rf #{path}`
    assert !dir.exists?
    dir.make
    assert dir.exists?
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '61FCE8',
  'disk[path].exists?(filename) false when file exists, true when it does' do
    `rm -rf #{path}`
    dir.make
    filename = 'hello.txt'
    assert !dir.exists?(filename)
    dir.write(filename, "content")
    assert dir.exists?(filename)
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '247EAB',
  'disk[path].read() reads back what was written' do
    expected = "content"
    dir.write('filename', expected)
    actual = dir.read('filename')
    assert_equal expected, actual
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '7B7E1A',
    'disk.lock throws exception, does not execute block,' +
       'and result is nil, when path does not exist' do
    block_run = false
    exception_thrown = false
    begin
      result = disk.lock('path_does_not_exist') do
        block_run = true
      end
    rescue
      exception_thrown = true
    end

    assert exception_thrown
    assert !block_run
    assert_nil result
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'BE0ED2',
    'when dir.lock is obtained block is executed' +
       'and result is result of block' do
    block_run = false
    begin
      result = dir.lock {
        block_run = true; 'Hello'
      }
      assert block_run, 'block_run'
      assert_equal 'Hello', result
    end
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '9E019E',
  'outer dir.lock is blocking so inner lock blocks' do
    outer_run = false
    inner_run = false
    dir.lock do
      outer_run = true

      inner_thread = Thread.new {
        dir.lock do
          inner_run = true
        end
      }
      max_seconds = 2
      inner_thread.join(max_seconds);
      if !inner_thread.nil?
        Thread.kill(inner_thread)
      end
    end
    assert outer_run
    assert !inner_run
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '0B1E7A',
    'holding lock on parent dir does not prevent' +
       'acquisition of lock on child dir' do
    parent_path = path + 'parent' + disk.dir_separator
    child_path = parent_path + 'child' + disk.dir_separator
    `mkdir #{parent_path}`
    `mkdir #{child_path}`
    parent_run = false
    child_run = false
    disk[parent_path].lock do
      parent_run = true
      disk[child_path].lock do
        child_run = true
      end
    end
    assert parent_run
    assert child_run
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '1C4A9F',
    'write(filename,s) raises RuntimeError when s is not a string' do
    assert_raises(RuntimeError) { dir.write('any.txt', Object.new) }
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '8F329F',
  'write(filename,s) succeeds when s is a string' do
    s = 'hello world'
    check_save_file('manifest.rb', s, s)
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '2BAC6D',
  'write_json(filename,s) raises RuntimeError when filename does not end in .json' do
    assert_raises(RuntimeError) { dir.write_json('file.txt', 'hello') }
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'F3B2F4',
  'write_json(filename,o) saves JSON.unparse(o) in filename' do
    dir.write_json(filename = 'object.json', { :a => 1, :b => 2 })
    json = dir.read(filename)
    o = JSON.parse(json)
    assert_equal 1, o['a']
    assert_equal 2, o['b']
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '95EA3F',
  'save file for non executable file' do
    check_save_file('file.a', 'content', 'content')
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'B5C931',
  'save file for executable file' do
    executable = true
    check_save_file('file.sh', 'ls', 'ls', executable)
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '51EE30',
  'save filename longer than but ends in makefile is not auto-tabbed' do
    content = '    abc'
    expected_content = content
    check_save_file('smakefile', content, expected_content)
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '25EACA',
  'disk.dir?(.) is true' do
    assert disk.dir?(path + '.')
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '75CA3F',
  'disk.dir?(..) is true' do
    assert disk.dir?(path + '..')
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '73E40A',
  'disk.dir?(not-a-dir) is false' do
    assert !disk.dir?('blah-blah')
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'AFEE82',
  'disk.dir?(a-dir) is true' do
    assert disk.dir?(path)
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '0CC3B9',
  'dir.each_dir' do
    cwd = `pwd`.strip + '/../'
    dirs = disk[cwd].each_dir.entries
    %w( app_helpers app_lib ).each { |dir_name| assert dirs.include?(dir_name), dir_name }
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '91E408',
  'disk[path].each_dir does not give filenames' do
    disk[path].make
    disk[path].write('beta.txt', 'content')
    disk[path + 'alpha'].make
    disk[path + 'alpha'].write('a.txt', 'a')
    assert_equal ['alpha'], disk[path].each_dir.entries
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '89211C',
  'disk[path].each_dir.select' do
    disk[path + 'alpha'].make
    disk[path + 'beta' ].make
    disk[path + 'alpha'].write('a.txt', 'a')
    disk[path + 'beta' ].write('b.txt', 'b')
    matches = disk[path].each_dir.select { |dir| dir.start_with?('a') }
    assert_equal ['alpha'], matches.sort
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '7CA54E',
  'disk[path].each_file' do
    disk[path + 'a'].make
    disk[path + 'a'].write('c.txt', 'content')
    disk[path + 'a'].write('d.txt', 'content')
    assert_equal ['c.txt','d.txt'], disk[path+'a'].each_file.entries.sort
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '500EA2',
  'disk[path].each_file does not give dirs' do
    disk[path].make
    disk[path].write('beta.txt', 'content')
    disk[path + 'alpha'].make
    disk[path + 'alpha'].write('a.txt', 'a')
    assert_equal ['beta.txt'], disk[path].each_file.entries
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'F569F8',
  'disk[path].each_file.select' do
    disk[path + 'a'].make
    disk[path + 'a'].write('b.cpp', 'content')
    disk[path + 'a'].write('c.txt', 'content')
    disk[path + 'a'].write('d.txt', 'content')
    matches = disk[path+'a'].each_file.select {|filename|
      filename.end_with?('.txt')
    }
    assert_equal ['c.txt','d.txt'], matches.sort
  end  
  
  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def check_save_file(filename, content, expected_content, executable = false)
    dir.write(filename, content)
    pathed_filename = path + filename
    assert File.exists?(pathed_filename),
          "File.exists?(#{pathed_filename})"
    assert_equal expected_content, IO.read(pathed_filename)
    assert_equal executable, File.executable?(pathed_filename),
                            'File.executable?(pathed_filename)'
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def split(id)
    id[0..1] + '/' + id[2..-1]
  end

  def make_dir_with_split_id(id)
    disk[path + split(id)].make
  end
  
end
