-- Jest Roblox Snapshot v1, http://roblox.github.io/jest-roblox/snapshot-testing

local exports = {}

exports[ [=[Store owners list should drill through interleaved intermediate components: 1: mount 1]=] ] = [=[

"[root]
  ▾ <Root>
    ▾ <Intermediate key=\"intermediate\">
        <Leaf key=\"leaf\">
      ▾ <Wrapper key=\"wrapper\">
          <Leaf>
      <Leaf key=\"leaf\">"
]=]

exports[ [=[Store owners list should drill through interleaved intermediate components: 2: components owned by <Root> 1]=] ] = [=[

"  ▾ <Root>
    ▾ <Intermediate key=\"intermediate\">
        <Leaf>
      <Leaf key=\"leaf\">"
]=]

exports[ [=[Store owners list should drill through interleaved intermediate components: 3: components owned by <Intermediate> 1]=] ] = [=[

"  ▾ <Intermediate key=\"intermediate\">
      <Leaf key=\"leaf\">
    ▾ <Wrapper key=\"wrapper\">"
]=]

exports[ [=[Store owners list should drill through intermediate components: 1: mount 1]=] ] = [=[

"[root]
  ▾ <Root>
    ▾ <Intermediate>
      ▾ <Wrapper>
          <Leaf>"
]=]

exports[ [=[Store owners list should drill through intermediate components: 2: components owned by <Root> 1]=] ] = [=[

"  ▾ <Root>
    ▾ <Intermediate>
        <Leaf>"
]=]

exports[ [=[Store owners list should drill through intermediate components: 3: components owned by <Intermediate> 1]=] ] = [=[

"  ▾ <Intermediate>
    ▾ <Wrapper>"
]=]

exports[ [=[Store owners list should show the proper owners list order and contents after insertions and deletions: 1: mount 1]=] ] = [=[

"[root]
  ▾ <Root>
    ▾ <Intermediate key=\"1\">
      ▾ <Wrapper>
          <Leaf>"
]=]

exports[ [=[Store owners list should show the proper owners list order and contents after insertions and deletions: 2: components owned by <Root> 1]=] ] = [=[

"  ▾ <Root>
    ▾ <Intermediate key=\"1\">
        <Leaf>"
]=]

exports[ [=[Store owners list should show the proper owners list order and contents after insertions and deletions: 3: update to add direct 1]=] ] = [=[

"[root]
  ▾ <Root>
      <Leaf key=\"1\">
    ▾ <Intermediate key=\"2\">
      ▾ <Wrapper>
          <Leaf>"
]=]

exports[ [=[Store owners list should show the proper owners list order and contents after insertions and deletions: 4: components owned by <Root> 1]=] ] = [=[

"  ▾ <Root>
      <Leaf key=\"1\">
    ▾ <Intermediate key=\"2\">
        <Leaf>"
]=]

exports[ [=[Store owners list should show the proper owners list order and contents after insertions and deletions: 5: update to remove indirect 1]=] ] = [=[

"[root]
  ▾ <Root>
      <Leaf key=\"1\">"
]=]

exports[ [=[Store owners list should show the proper owners list order and contents after insertions and deletions: 6: components owned by <Root> 1]=] ] = [=[

"  ▾ <Root>
      <Leaf key=\"1\">"
]=]

exports[ [=[Store owners list should show the proper owners list order and contents after insertions and deletions: 7: update to remove both 1]=] ] = [=[

"[root]
    <Root>"
]=]

exports[ [=[Store owners list should show the proper owners list order and contents after insertions and deletions: 8: components owned by <Root> 1]=] ] = [=[
"    <Root>"]=]

exports[ [=[Store owners list should show the proper owners list ordering after reordered children: 1: mount (ascending) 1]=] ] = [=[

"[root]
  ▾ <Root>
      <Leaf key=\"A\">
      <Leaf key=\"B\">
      <Leaf key=\"C\">"
]=]

exports[ [=[Store owners list should show the proper owners list ordering after reordered children: 2: components owned by <Root> 1]=] ] = [=[

"  ▾ <Root>
      <Leaf key=\"A\">
      <Leaf key=\"B\">
      <Leaf key=\"C\">"
]=]

exports[ [=[Store owners list should show the proper owners list ordering after reordered children: 3: update (descending) 1]=] ] = [=[

"[root]
  ▾ <Root>
      <Leaf key=\"C\">
      <Leaf key=\"B\">
      <Leaf key=\"A\">"
]=]

exports[ [=[Store owners list should show the proper owners list ordering after reordered children: 4: components owned by <Root> 1]=] ] = [=[

"  ▾ <Root>
      <Leaf key=\"C\">
      <Leaf key=\"B\">
      <Leaf key=\"A\">"
]=]

return exports