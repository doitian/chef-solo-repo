class Cookbook < Thor
  desc "create NAME [OPTIONS]", "run `knife cookbook create [OPTIONS]`"
  def create(name, *args)
    system 'bundle', 'exec', 'knife', 'cookbook', 'create', name, *args
  end

  desc "search QUERY [OPTIONS]", "run `knife cookbook site search QUERY [OPTIONS]`"
  def search(query, *args)
    system 'bundle', 'exec', 'knife', 'cookbook', 'site', 'search', query, *args
  end

  desc "download COOKBOOK [OPTIONS]", "run `knife cookbook site download COOKBOOK [OPTIONS]`"
  def download(cookbook, *args)
    system 'bundle', 'exec', 'knife', 'cookbook', 'site', 'download', cookbook, *args
  end

  desc "install COOKBOOK [OPTIONS]", "run `knife cookbook site install COOKBOOK [OPTIONS]`"
  def install(cookbook, *args)
    system 'bundle', 'exec', 'knife', 'cookbook', 'site', 'install', cookbook, *args
  end
end
