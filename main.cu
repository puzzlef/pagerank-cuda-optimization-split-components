#include <vector>
#include <cstdio>
#include <iostream>
#include "src/main.hxx"

using namespace std;




#define SPLIT true
#define SORT  true

template <class G, class H>
void runPagerank(const G& x, const H& xt, int repeat) {
  enum NormFunction { L0=0, L1=1, L2=2, Li=3 };
  vector<float> *init = nullptr;

  // Find pagerank using nvGraph.
  auto a1 = pagerankNvgraph(x, xt, init, {repeat, L1});
  auto e1 = l1Norm(a1.ranks, a1.ranks);
  printf("[%09.3f ms; %03d iters.] [%.4e err.] pagerankNvgraph\n", a1.time, a1.iterations, e1);

  // Find pagerank without optimization.
  auto a2 = pagerankMonolithicCuda(x, xt, init, {repeat, L1});
  auto e2 = l1Norm(a2.ranks, a1.ranks);
  printf("[%09.3f ms; %03d iters.] [%.4e err.] pagerankCuda\n", a2.time, a2.iterations, e2);

  // Find pagerank with vertices split by components.
  for (int MC=1, i=0; MC<=5e+7; MC*=i&1? 2:5, i++) {
    auto a3 = pagerankMonolithicCuda(x, xt, init, {repeat, L1, MC, SPLIT});
    auto e3 = l1Norm(a3.ranks, a1.ranks);
    printf("[%09.3f ms; %03d iters.] [%.4e err.] pagerankCudaSplit [min-compute=%d]\n", a3.time, a3.iterations, e3, MC);
  }

  // Find pagerank with components sorted in topological order.
  for (int MC=1, i=0; MC<=5e+7; MC*=i&1? 2:5, i++) {
    auto a4 = pagerankMonolithicCuda(x, xt, init, {repeat, L1, MC, SPLIT, SORT});
    auto e4 = l1Norm(a4.ranks, a1.ranks);
    printf("[%09.3f ms; %03d iters.] [%.4e err.] pagerankCudaSplitSort [min-compute=%d]\n", a4.time, a4.iterations, e4, MC);
  }
}


int main(int argc, char **argv) {
  char *file = argv[1];
  int repeat = argc>2? stoi(argv[2]) : 5;
  printf("Loading graph %s ...\n", file);
  auto x  = readMtx(file); println(x);
  auto xt = transposeWithDegree(x); print(xt); printf(" (transposeWithDegree)\n");
  runPagerank(x, xt, repeat);
  printf("\n");
  return 0;
}
