/*!
	\class CPP_PageNode
	\brief A class which can be used to represent HTML DOM as a tree
*/

#include <string>
using std::string;

class CPP_PageNode;

class CPP_PageNode {
	private:
		// The HTML tag for this node
		string tag = "";
		// Mem Ref of child tag
		CPP_PageNode* child_node = nullptr;
		// Mem ref of neighbour tag. (Linked list of elems sharing a parent)
		CPP_PageNode* neighbor_node = nullptr;
		bool is_text_node = false;

	public:
		CPP_PageNode(const char t[], bool text_node) {
			tag = t;
			is_text_node = text_node;
		}

		CPP_PageNode(const char t[], bool text_node, CPP_PageNode* c) {
			tag = t;
			is_text_node = text_node;
			c->append_child_node(this);
		}

		void set_tag(string s) {
			tag = s;
		}

		bool is_text() { return is_text_node; }
		bool has_child() { return child_node != nullptr; }
		bool has_neighbor() { return neighbor_node != nullptr; }

		CPP_PageNode* get_child_node() {
			return child_node;
		}

		void append_child_node(CPP_PageNode* c) {
			if (has_child() == false) {
				child_node = c;
			}
			else {
				get_child_node() ->append_neighbor_node(c);
			}
		}


		string get_tag() {
			return tag;
		}

		CPP_PageNode* get_neighbor_node() {
			return neighbor_node;
		}

		void append_neighbor_node(CPP_PageNode* n) {
			if (has_neighbor() == false) {
				neighbor_node = n;
			}
			else {
				get_neighbor_node() -> append_neighbor_node(n);
			}
		}

		string draw_me_and_my_child() {
			string str = get_tag();
			if (has_child() == true) {
				str.append(get_child_node()->draw_me_and_my_child());

			}

			if (is_text() != true) {
				str.append(tag.insert(1, "/"));
			}

			if (has_neighbor() == true) {
				str.append(get_neighbor_node() -> draw_me_and_my_child());
			}
			return str;
		}

		void dissassemble(){
			if (has_child() == true) {
				get_child_node() -> dissassemble();
				delete(get_child_node());
			}

			if (has_neighbor() == true) {
				get_neighbor_node() -> dissassemble();
				delete(get_neighbor_node());
			}
		}

};
