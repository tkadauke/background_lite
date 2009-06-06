class Object
  # Clones the object to for transmission to the background process. The default
  # implementation is dupping the object.
  def clone_for_background
    dup
  end
end
