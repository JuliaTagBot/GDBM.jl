function Base.getindex(dbm::DBM, key::Union{String,Array{UInt8,1}})
  datum = gdbm_fetch(dbm.handle, Datum(key))
  value = unsafe_string(datum.dptr, datum.dsize)
  libc_free(datum.dptr)
  value
end
  

function Base.setindex!(dbm::DBM, value::Union{String,Array{UInt8,1}}, key::Union{String,Array{UInt8,1}})
  gdbm_store(dbm.handle, Datum(key), Datum(value))
  key
end

Base.start(dbm::DBM) = gdbm_firstkey(dbm.handle)

Base.done(dbm::DBM, state::Datum) = state.dptr == C_NULL

function Base.next(dbm::DBM, prev::Datum)
  key = unsafe_string(prev.dptr, prev.dsize)
  datum = gdbm_fetch(dbm.handle, prev)
  value = unsafe_string(datum.dptr, datum.dsize)
  libc_free(datum.dptr)
  next = gdbm_nextkey(dbm.handle, prev)
  libc_free(prev.dptr)
  ((key, value), next)
end

Base.length(dbm::DBM) = gdbm_count(dbm.handle)

Base.eltype(::Type{DBM}) = Union{Pair{String,String},Pair{String,Array{UInt8,1}},Pair{Array{UInt8,1},String},Pair{Array{UInt8,1},Array{UInt8,1}}}

Base.keytype(::Type{DBM}) = String

Base.valtype(::Type{DBM}) = String

Base.haskey(dbm::DBM, key::Union{String,Array{UInt8,1}}) = gdbm_exists(dbm.handle, Datum(key))

function Base.delete!(dbm::DBM, key::String)
  gdbm_delete(dbm.handle, Datum(key))
  dbm
end

function Base.pop!(dbm::DBM, key::Union{String,Array{UInt8,1}}, default = nothing)
  datum = Datum(key)
  if gdbm_exists(dbm.handle, datum)
    vdatum = gdbm_fetch(dbm.handle, datum)
    value = unsafe_string(vdatum.dptr, vdatum.dsize)
    libc_free(vdatum.dptr)
    gdbm_delete(dbm.handle, datum)
    return value
  end
  default isa String && return default
  throw(KeyError(key))
end

function Base.getkey(dbm::DBM, key::Union{String,Array{UInt8,1}}, default::String)
  gdbm_exists(dbm.handle, Datum(key)) && return key
  default
end

function Base.get(dbm::DBM, key::Union{String,Array{UInt8,1}}, default::String)
  value = default
  datum = Datum(key)
  if gdbm_exists(dbm.handle, datum)
    datum = gdbm_fetch(dbm.handle, datum)
    value = unsafe_string(datum.dptr, datum.dsize)
    libc_free(datum.dptr)
  end
  value
end

function Base.get!(dbm::DBM, key::Union{String,Array{UInt8,1}}, default::String)
  value = default
  datum = Datum(key)
  if gdbm_exists(dbm.handle, datum)
    vdatum = gdbm_fetch(dbm.handle, datum)
    value = unsafe_string(vdatum.dptr, vdatum.dsize)
    libc_free(vdatum.dptr)
  else
    gdbm_store(dbm.handle, datum, Datum(default))
  end
  value
end

function Base.isempty(dbm::DBM)
  gdbm_count(dbm.handle) == 0 && return true
  false
end

function Base.empty!(dbm::DBM)
  prev = gdbm_firstkey(dbm.handle)
  while prev.dptr ≠ C_NULL
    key = unsafe_string(prev.dptr, prev.dsize)
    next = gdbm_nextkey(dbm.handle, prev)
    gdbm_delete(dbm.handle, prev)
    libc_free(prev.dptr)
    prev = next
  end
end

function Base.in(pair::Union{Pair{String,String},Pair{String,Array{UInt8,1}},Pair{Array{UInt8,1},String},Pair{Array{UInt8,1},Array{UInt8,1}}}, dbm::DBM)
  datum = Datum(pair.first)
  !gdbm_exists(dbm.handle, datum) && return false
  vdatum = gdbm_fetch(dbm.handle, datum)
  value = unsafe_string(vdatum.dptr, vdatum.dsize)
  libc_free(vdatum.dptr)
  value == pair.second
end